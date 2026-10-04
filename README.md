# iceibank
Trabalho Prático do Laboratório de Desenvolvimento de Aplicações Móveis e Distribuídas

## Conta de administrador

O administrador faz login em `/admin/entrar` no frontend e pode criar contas com saldo inicial, depositar, sacar e transferir entre quaisquer contas das 3 agências. Serve para testar o sistema sem usar o terminal.

As credenciais vêm de variáveis de ambiente, definidas ao iniciar cada agência. Sem elas, o login de administrador fica desabilitado (resposta 503).

```powershell
cd "C:\faculdade\Lab\iceibank\agencia"
$env:AGENCIA_ID = "0"
$env:ICEIBANK_ADMIN_USUARIO = "admin"
$env:ICEIBANK_ADMIN_SENHA = "<escolha uma senha>"
py src/main.py
```

Use o mesmo usuário e a mesma senha nas 3 agências, porque o token de administrador é aceito por todas.
