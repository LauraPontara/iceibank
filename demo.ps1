# Sobe tudo para demonstrar o ICEIBank: RabbitMQ, as 3 agencias, o site e o app no celular.
#
#   powershell -ExecutionPolicy Bypass -File .\demo.ps1               sobe tudo
#   powershell -ExecutionPolicy Bypass -File .\demo.ps1 -SemCelular   sobe so o computador
#   powershell -ExecutionPolicy Bypass -File .\demo.ps1 -Reconstruir  recompila o app mesmo sem mudancas
#   powershell -ExecutionPolicy Bypass -File .\demo.ps1 -Ip 10.0.0.5  informa o IP do computador na rede
#   powershell -ExecutionPolicy Bypass -File .\demo.ps1 -Parar        desliga tudo

param(
    [switch]$Parar,
    [switch]$SemCelular,
    [switch]$Reconstruir,
    [string]$Ip
)

$ErrorActionPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$raiz = $PSScriptRoot
$pastaApp = Join-Path $raiz 'app_mobile'
$pastaAgencia = Join-Path $raiz 'agencia'
$arquivoPids = Join-Path $env:LOCALAPPDATA 'iceibank-demo-pids.txt'
$pacoteApp = 'br.pucminas.iceibank.iceibank_mobile'
$containerRabbit = 'rabbitmq-iceibank'
$urlRabbit = 'amqp://guest:guest@localhost:5672/'
$portasAgencias = 4030, 4031, 4032
$portaSite = 5500
$adminUsuario = 'admin'
$adminSenha = 'admin1234'
$senhaContas = 'demo1234'

# O numero da conta define a agencia (id % 3). A lider inicial e a Agencia 2, entao
# a conta principal fica na Agencia 0 e continua de pe quando a lider e derrubada.
$contas = @(
    @{ id = 1002; nome = 'Ana Souza'; saldo = 1000; uso = 'Principal: use para failover e modo offline' },
    @{ id = 1005; nome = 'Bruno Lima'; saldo = 250; uso = 'Transferencia na mesma agencia (Agencia 0)' },
    @{ id = 1000; nome = 'Carla Dias'; saldo = 500; uso = 'Transferencia entre agencias (Agencia 1)' },
    @{ id = 1001; nome = 'Diego Alves'; saldo = 750; uso = 'Fica na Agencia 2: some se ela cair' }
)

function Etapa($texto) { Write-Host "`n>> $texto" -ForegroundColor Magenta }
function Ok($texto) { Write-Host "   $texto" -ForegroundColor Green }
function Aviso($texto) { Write-Host "   $texto" -ForegroundColor Yellow }
function Falhar($texto) { Write-Host "`nERRO: $texto" -ForegroundColor Red; exit 1 }

function Encerrar-Processos {
    if (Test-Path $arquivoPids) {
        Get-Content $arquivoPids | ForEach-Object { taskkill /PID $_ /T /F 2>$null | Out-Null }
        Remove-Item $arquivoPids -ErrorAction SilentlyContinue
    }
    foreach ($porta in ($portasAgencias + $portaSite)) {
        Get-NetTCPConnection -LocalPort $porta -State Listen -ErrorAction SilentlyContinue | ForEach-Object {
            Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
        }
    }
}

function Docker-Pronto {
    docker info *> $null
    return $LASTEXITCODE -eq 0
}

# Olha quem esta escutando em vez de conectar: o site escuta so em IPv6 no Windows
function Porta-Aberta($porta) {
    return [bool](Get-NetTCPConnection -LocalPort $porta -State Listen -ErrorAction SilentlyContinue)
}

function Abrir-Janela($titulo, $comandos) {
    $script = "`$Host.UI.RawUI.WindowTitle = '$titulo'; $comandos"
    $codificado = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($script))
    $processo = Start-Process powershell.exe -PassThru -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-EncodedCommand', $codificado
    Add-Content -Path $arquivoPids -Value $processo.Id
}

function Subir-RabbitMQ {
    Etapa 'Docker e RabbitMQ'
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { Falhar 'Docker não encontrado. Instale o Docker Desktop.' }
    if (-not (Docker-Pronto)) {
        Aviso 'Abrindo o Docker Desktop, pode levar um minuto...'
        Start-Process 'C:\Program Files\Docker\Docker\Docker Desktop.exe' -ErrorAction SilentlyContinue
        $limite = (Get-Date).AddMinutes(3)
        while (-not (Docker-Pronto)) {
            if ((Get-Date) -gt $limite) { Falhar 'O Docker não ficou pronto em 3 minutos. Abra o Docker Desktop e rode de novo.' }
            Start-Sleep 3
        }
    }
    $existe = docker ps -a --filter "name=^$containerRabbit$" --format '{{.Names}}'
    if ($existe) {
        docker start $containerRabbit | Out-Null
    } else {
        docker run -d --name $containerRabbit -p 5672:5672 -p 15672:15672 rabbitmq:3-management | Out-Null
    }
    $limite = (Get-Date).AddMinutes(2)
    while (-not (Porta-Aberta 5672)) {
        if ((Get-Date) -gt $limite) { Falhar 'O RabbitMQ não abriu a porta 5672 em 2 minutos.' }
        Start-Sleep 1
    }
    Ok 'RabbitMQ no ar (painel em http://localhost:15672, guest/guest)'
}

function Garantir-Dependencias-Python {
    py -c "import fastapi, uvicorn, pika, jwt, requests" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Aviso 'Instalando as dependências do backend...'
        py -m pip install -q -r (Join-Path $pastaAgencia 'requirements.txt')
        if ($LASTEXITCODE -ne 0) { Falhar 'Não foi possível instalar as dependências do backend.' }
    }
}

function Subir-Agencias {
    Etapa 'Agências (uma janela para cada)'
    Garantir-Dependencias-Python
    Remove-Item (Join-Path $pastaAgencia 'data\*.jsonl') -ErrorAction SilentlyContinue
    0..2 | ForEach-Object {
        Abrir-Janela "Agencia $_" (
            "Set-Location '$pastaAgencia'; `$env:AGENCIA_ID='$_'; `$env:RABBITMQ_URL='$urlRabbit'; " +
            "`$env:ICEIBANK_ADMIN_USUARIO='$adminUsuario'; `$env:ICEIBANK_ADMIN_SENHA='$adminSenha'; `$env:PYTHONUNBUFFERED='1'; py src/main.py"
        )
    }
    $limite = (Get-Date).AddSeconds(45)
    do {
        Start-Sleep 1
        $lideres = @($portasAgencias | ForEach-Object {
            try { (Invoke-RestMethod "http://127.0.0.1:$_/bully/lider" -TimeoutSec 2).liderAtual } catch { $null }
        })
        $convergiu = ($lideres | Where-Object { $_ -ne $null }).Count -eq 3 -and ($lideres | Select-Object -Unique).Count -eq 1
    } until ($convergiu -or (Get-Date) -gt $limite)
    if (-not $convergiu) { Falhar 'As agências não convergiram para uma líder. Veja as janelas delas.' }
    Ok "3 agências no ar. Líder atual: Agência $($lideres[0])"
    return $lideres[0]
}

function Criar-Contas {
    Etapa 'Contas de teste'
    foreach ($conta in $contas) {
        $porta = 4030 + ($conta.id % 3)
        $corpo = @{ id = $conta.id; nomeAluno = $conta.nome; senha = $senhaContas; saldoInicial = $conta.saldo } | ConvertTo-Json
        try {
            Invoke-RestMethod "http://127.0.0.1:$porta/contas" -Method Post -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($corpo)) | Out-Null
        } catch {
            if ([int]$_.Exception.Response.StatusCode -ne 409) { Falhar "Não foi possível criar a conta $($conta.id): $($_.Exception.Message)" }
        }
    }
    Ok "$($contas.Count) contas criadas"
}

function Subir-Site {
    Etapa 'Site'
    $pastaFrontend = Join-Path $raiz 'frontend'
    if (-not (Test-Path (Join-Path $pastaFrontend 'node_modules'))) {
        Aviso 'Instalando as dependências do site...'
        Push-Location $pastaFrontend
        npm ci --silent
        Pop-Location
    }
    Abrir-Janela 'Site ICEIBank' "Set-Location '$pastaFrontend'; npm run dev -- --port $portaSite --strictPort"
    $limite = (Get-Date).AddSeconds(30)
    while (-not (Porta-Aberta $portaSite) -and (Get-Date) -lt $limite) { Start-Sleep 1 }
    if (Porta-Aberta $portaSite) { Ok "Site em http://localhost:$portaSite" } else { Aviso 'O site ainda não respondeu. Veja a janela dele.' }
}

function Caminho-Adb {
    $comando = Get-Command adb -ErrorAction SilentlyContinue
    if ($comando) { return $comando.Source }
    return Join-Path $env:ANDROID_HOME 'platform-tools\adb.exe'
}

function Aguardar-Celular($adb) {
    Etapa 'Celular'
    Write-Host '   Conecte o celular no USB, com a depuração USB ativa. Esperando...'
    $avisouAutorizacao = $false
    while ($true) {
        $linhas = & $adb devices 2>$null | Select-Object -Skip 1 | Where-Object { $_ -match '\S' }
        $pronto = $linhas | Where-Object { $_ -match '\sdevice$' } | Select-Object -First 1
        if ($pronto) { return ($pronto -split '\s+')[0] }
        if (($linhas -match 'unauthorized') -and -not $avisouAutorizacao) {
            Aviso 'Aceite o pedido de depuração USB na tela do celular.'
            $avisouAutorizacao = $true
        }
        Start-Sleep 2
    }
}

function IPs-Do-Computador {
    return @(Get-NetIPConfiguration | Where-Object {
        $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq 'Up' -and $_.InterfaceAlias -notmatch 'vEthernet|WSL|Loopback|Bluetooth'
    } | ForEach-Object { $_.IPv4Address.IPAddress })
}

function Escolher-IP($ipCelular) {
    if ($Ip) { return $Ip }
    $candidatos = IPs-Do-Computador
    if ($ipCelular) {
        $prefixo = $ipCelular.Substring(0, $ipCelular.LastIndexOf('.') + 1)
        $mesmaRede = $candidatos | Where-Object { $_.StartsWith($prefixo) } | Select-Object -First 1
        if ($mesmaRede) { return $mesmaRede }
        Aviso "O celular ($ipCelular) não está na mesma rede do computador ($($candidatos -join ', ')). Conecte os dois no mesmo Wi-Fi."
    }
    return $candidatos | Select-Object -First 1
}

function Caminho-Flutter {
    $comando = Get-Command flutter -ErrorAction SilentlyContinue
    if ($comando) { return $comando.Source }
    if (Test-Path 'C:\dev\flutter\bin\flutter.bat') { return 'C:\dev\flutter\bin\flutter.bat' }
    Falhar 'Flutter não encontrado. Instale o SDK ou coloque-o no PATH.'
}

function Compilar-App($ipServidor) {
    $apk = Join-Path $pastaApp 'build\app\outputs\flutter-apk\app-debug.apk'
    $marca = Join-Path $env:LOCALAPPDATA 'iceibank-demo-build.txt'

    # So recompila quando algo mudou: e o passo mais demorado do script
    $atualizado = $false
    if ((Test-Path $apk) -and (Test-Path $marca) -and -not $Reconstruir) {
        $data = (Get-Item $apk).LastWriteTimeUtc
        $fontes = @(Get-ChildItem (Join-Path $pastaApp 'lib') -Recurse -File) + @(Get-Item (Join-Path $pastaApp 'pubspec.yaml')) + @(Get-ChildItem (Join-Path $pastaApp 'android\app\src') -Recurse -File)
        $maisNova = ($fontes | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1).LastWriteTimeUtc
        $atualizado = (Get-Content $marca -Raw).Trim() -eq "$ipServidor|$($data.Ticks)" -and $maisNova -lt $data
    }
    if ($atualizado) {
        Ok 'App já compilado para este endereço'
        return $apk
    }

    Aviso 'Compilando o app, pode levar de 1 a 3 minutos...'
    $flutter = Caminho-Flutter
    New-Item -ItemType Directory -Force 'C:\dev\tmp', 'C:\dev\pub-cache' | Out-Null
    $env:TEMP = 'C:\dev\tmp'
    $env:TMP = 'C:\dev\tmp'
    $env:PUB_CACHE = 'C:\dev\pub-cache'
    $env:JAVA_TOOL_OPTIONS = '-Djdk.net.unixdomain.tmpdir=C:\dev\tmp'
    $log = Join-Path 'C:\dev\tmp' 'iceibank-build.log'
    Push-Location $pastaApp
    & $flutter build apk --debug "--dart-define=AGENCIA_HOST=$ipServidor" *> $log
    $codigo = $LASTEXITCODE
    Pop-Location
    Remove-Item Env:\JAVA_TOOL_OPTIONS -ErrorAction SilentlyContinue
    if ($codigo -ne 0) { Falhar "A compilação do app falhou. Veja o log em $log" }
    Set-Content -Path $marca -Value "$ipServidor|$((Get-Item $apk).LastWriteTimeUtc.Ticks)"
    Ok 'App compilado'
    return $apk
}

function Instalar-App($adb, $serial, $apk) {
    # O Xiaomi as vezes recusa a instalacao pelo cabo e aceita na tentativa seguinte
    for ($tentativa = 1; $tentativa -le 3; $tentativa++) {
        $saida = & $adb -s $serial install -r -t $apk 2>&1 | Out-String
        if ($saida -match 'Success') {
            # Comeca limpo: sem sessao, fila ou endereco de uma execucao anterior
            & $adb -s $serial shell pm clear $pacoteApp 2>&1 | Out-Null
            & $adb -s $serial shell monkey -p $pacoteApp -c android.intent.category.LAUNCHER 1 2>&1 | Out-Null
            Ok 'App instalado e aberto no celular'
            return
        }
        Aviso "Instalação recusada (tentativa $tentativa de 3). Se aparecer um aviso no celular, aceite."
        Start-Sleep 3
    }
    Falhar "O celular recusou a instalação: $saida"
}

function Mostrar-Resumo($lider, $ipServidor) {
    Write-Host "`n========================= ICEIBANK PRONTO =========================" -ForegroundColor Magenta
    Write-Host "`nContas de teste (senha de todas: $senhaContas)`n" -ForegroundColor White
    $contas | ForEach-Object {
        [pscustomobject]@{
            Conta   = $_.id
            Senha   = $senhaContas
            Titular = $_.nome
            Agencia = $_.id % 3
            Saldo   = 'R$ {0:N2}' -f $_.saldo
            Uso     = $_.uso
        }
    } | Format-Table -AutoSize | Out-String | Write-Host
    Write-Host "Líder atual:     Agência $lider"
    Write-Host "Site:            http://localhost:$portaSite"
    Write-Host "Admin no site:   $adminUsuario / $adminSenha (http://localhost:$portaSite/admin/entrar)"
    if ($ipServidor) { Write-Host "App aponta para: $ipServidor (portas $($portasAgencias -join ', '))" }
    Write-Host "`nPara demonstrar o failover: feche a janela 'Agencia 2' e olhe o painel do app."
    Write-Host 'Para o histórico de líderes: cd agencia; py historico_lideranca.py'
    Write-Host 'Para desligar tudo:          powershell -ExecutionPolicy Bypass -File .\demo.ps1 -Parar'
    Write-Host ''
}

if ($Parar) {
    Etapa 'Desligando'
    Encerrar-Processos
    if ((Get-Command docker -ErrorAction SilentlyContinue) -and (Docker-Pronto)) { docker stop $containerRabbit 2>$null | Out-Null }
    Ok 'Agências, site e RabbitMQ desligados'
    exit 0
}

Encerrar-Processos
Subir-RabbitMQ
$lider = Subir-Agencias
Criar-Contas
Subir-Site

$ipServidor = $null
if ($SemCelular) {
    $ipServidor = Escolher-IP $null
} else {
    $adb = Caminho-Adb
    $serial = Aguardar-Celular $adb
    $saidaIp = & $adb -s $serial shell ip -f inet addr show wlan0 2>$null | Out-String
    $ipCelular = if ($saidaIp -match 'inet (\d+\.\d+\.\d+\.\d+)') { $Matches[1] } else { $null }
    if (-not $ipCelular) { Aviso 'O Wi-Fi do celular parece desligado. Ligue na mesma rede do computador.' }
    $ipServidor = Escolher-IP $ipCelular
    if (-not $ipServidor) { Falhar 'Não encontrei o IP do computador na rede. Rode de novo com -Ip <endereço>.' }
    Ok "Celular $serial. O app vai usar as agências em $ipServidor"
    $apk = Compilar-App $ipServidor
    Instalar-App $adb $serial $apk
}

Mostrar-Resumo $lider $ipServidor
