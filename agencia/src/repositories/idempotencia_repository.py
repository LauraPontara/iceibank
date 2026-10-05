import threading


class IdempotenciaRepository:
    """Guarda o resultado de transferencias ja concluidas, indexado pela
    chave de idempotencia enviada pelo cliente."""

    def __init__(self):
        self._resultados = {}
        self._lock = threading.Lock()

    def obter(self, chave: str) -> dict | None:
        with self._lock:
            return self._resultados.get(chave)

    def registrar(self, chave: str, resultado: dict) -> None:
        with self._lock:
            self._resultados[chave] = resultado

    def registrar_se_novo(self, chave: str) -> bool:
        """Marca a chave como vista. Devolve False se ja tinha sido marcada."""
        with self._lock:
            if chave in self._resultados:
                return False
            self._resultados[chave] = {}
            return True
