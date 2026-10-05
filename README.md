# iceibank
Trabalho Prático do Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas

## RabbitMQ (Sprint 2)

As agências trocam créditos entre si por mensageria. O RabbitMQ roda local em Docker:

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
