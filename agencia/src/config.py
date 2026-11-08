import os

# OFFSET pessoal (2 ultimos digitos da matricula/RA), necessario apenas
# se for rodar em uma maquina compartilhada do laboratorio.
OFFSET = 30

NUMERO_AGENCIAS = 3
PORTA_BASE = 4000 + OFFSET

# 127.0.0.1 em vez de localhost: no Windows o localhost tenta IPv6 antes e perde
# cerca de 1s em cada chamada, o mesmo valor do timeout da eleicao de lider.
AGENCIAS = [
    {"id": 0, "url": f"http://127.0.0.1:{PORTA_BASE}"},
    {"id": 1, "url": f"http://127.0.0.1:{PORTA_BASE + 1}"},
    {"id": 2, "url": f"http://127.0.0.1:{PORTA_BASE + 2}"},
]


def agencia_responsavel(id_conta: int) -> int:
    return id_conta % NUMERO_AGENCIAS


# Chave usada para assinar os JWT. Em producao isso viria de uma variavel de
# ambiente/segredo gerenciado - aqui fica um valor fixo de desenvolvimento.
JWT_SECRET = "iceibank-dev-secret-troque-em-producao"
JWT_ALGORITMO = "HS256"
JWT_EXPIRA_MINUTOS = 15


# Credenciais do administrador, lidas do ambiente. Sem as duas variaveis o
# login de administrador fica desabilitado.
ADMIN_USUARIO = os.environ.get("ICEIBANK_ADMIN_USUARIO")
ADMIN_SENHA = os.environ.get("ICEIBANK_ADMIN_SENHA")
