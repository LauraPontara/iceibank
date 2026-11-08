# iceibank
Trabalho Prático do Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas

## RabbitMQ (Sprint 2)

As agências trocam créditos entre si por mensageria. O broker pode ser uma instância gratuita no CloudAMQP (plano Little Lemur, o caminho principal do roteiro) ou um RabbitMQ local em Docker. A aplicação funciona igual nos dois casos, só muda o valor de `RABBITMQ_URL`.

Com o CloudAMQP, copie a AMQP URL da instância (ela contém a senha, então não a coloque em commits) e defina a variável antes de iniciar cada agência:

```powershell
$env:RABBITMQ_URL = "amqps://usuario:senha@host.cloudamqp.com/vhost"
```

Para rodar local, em Docker:

```powershell
docker run -d --name rabbitmq-iceibank -p 5672:5672 -p 15672:15672 rabbitmq:3-management
```

O painel fica em http://localhost:15672. Antes de iniciar cada agência, defina a URL do broker:

```powershell
$env:RABBITMQ_URL = "amqp://guest:guest@localhost:5672/"
```

Sem `RABBITMQ_URL` a agência não sobe. A exchange `iceibank.eventos` (topic), as filas `fila-agencia-N` e a fila de mensagens mortas `fila-mensagens-mortas` são criadas automaticamente. Se as filas já existirem sem o argumento de dead-letter (criadas por uma versão anterior), apague-as uma vez com `docker exec rabbitmq-iceibank rabbitmqctl delete_queue fila-agencia-0` (e `-1`, `-2`).

Testes do relógio vetorial e linha do tempo causal:

```powershell
cd agencia
python -m unittest discover -s tests
python mesclar_logs.py
```

## Conta de administrador

O administrador faz login em `/admin/entrar` no frontend e pode criar contas com saldo inicial, depositar, sacar e transferir entre quaisquer contas das 3 agências. Serve para testar o sistema sem usar o terminal.

As credenciais vêm de variáveis de ambiente, definidas ao iniciar cada agência. Sem elas, o login de administrador fica desabilitado (resposta 503).

```powershell
cd "C:\faculdade\Lab\iceibank\agencia"
$env:AGENCIA_ID = "0"
$env:RABBITMQ_URL = "amqp://guest:guest@localhost:5672/"
$env:ICEIBANK_ADMIN_USUARIO = "admin"
$env:ICEIBANK_ADMIN_SENHA = "<escolha uma senha>"
py src/main.py
```

Use o mesmo usuário e a mesma senha nas 3 agências, porque o token de administrador é aceito por todas.

## Demonstração

O script `demo.ps1` sobe o RabbitMQ, as 3 agências e o site, cria as contas de teste, instala o app no celular conectado por USB e mostra no final os dados de login e os saldos. O celular precisa estar no mesmo Wi-Fi do computador.

```powershell
powershell -ExecutionPolicy Bypass -File .\demo.ps1
powershell -ExecutionPolicy Bypass -File .\demo.ps1 -Parar
```

## Eleição de líder (Sprint 3)

Ao subir, cada agência dispara uma eleição pelo algoritmo de Bully e passa a verificar a líder a cada 3 segundos. Para consultar quem é a líder e reconstruir o histórico de lideranças a partir dos logs:

```powershell
Invoke-RestMethod -Uri "http://localhost:4030/bully/lider" -Method Get
cd agencia
python historico_lideranca.py
```

## App Flutter (Sprint 3)

O app fica em `app_mobile/` e fala com as agências pela rede Wi-Fi, então celular e computador precisam estar na mesma rede. Com o celular conectado por USB e a depuração ativa:

```powershell
cd app_mobile
flutter pub get
flutter run --dart-define=AGENCIA_HOST=<IP do computador no Wi-Fi>
```

O IP também pode ser trocado na tela de login. Os testes de integração rodam no próprio celular, com as 3 agências no ar:

```powershell
flutter test integration_test --dart-define=AGENCIA_HOST=<IP do computador no Wi-Fi>
```
