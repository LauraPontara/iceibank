class ContaRepository:
    """Armazena as contas da agencia em memoria. Toda leitura e escrita de
    contas passa por aqui, para que a persistencia possa ser trocada depois
    (arquivo, banco) sem mexer nos controllers."""

    def __init__(self):
        self._contas = {}

    def existe(self, id_conta: int) -> bool:
        return id_conta in self._contas

    def obter(self, id_conta: int) -> dict | None:
        conta = self._contas.get(id_conta)
        return dict(conta) if conta is not None else None

    def listar(self) -> list[dict]:
        return [dict(c) for c in sorted(self._contas.values(), key=lambda c: c["id"])]

    def contar(self) -> int:
        return len(self._contas)

    def criar(self, id_conta: int, nome_aluno: str, senha_hash: str, saldo: float) -> dict:
        self._contas[id_conta] = {
            "id": id_conta,
            "nomeAluno": nome_aluno,
            "senhaHash": senha_hash,
            "saldo": saldo,
        }
        return dict(self._contas[id_conta])

    def creditar(self, id_conta: int, valor: float) -> dict:
        conta = self._contas[id_conta]
        conta["saldo"] += valor
        return dict(conta)

    def debitar(self, id_conta: int, valor: float) -> dict:
        conta = self._contas[id_conta]
        conta["saldo"] -= valor
        return dict(conta)
