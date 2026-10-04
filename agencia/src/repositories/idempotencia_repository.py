class IdempotenciaRepository:
    """Guarda o resultado de transferencias ja concluidas, indexado pela
    chave de idempotencia enviada pelo cliente."""

    def __init__(self):
        self._resultados = {}

    def obter(self, chave: str) -> dict | None:
        return self._resultados.get(chave)

    def registrar(self, chave: str, resultado: dict) -> None:
        self._resultados[chave] = resultado
