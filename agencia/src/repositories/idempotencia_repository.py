import threading

_EM_ANDAMENTO = object()


class IdempotenciaRepository:
    """Guarda o resultado de transferencias ja concluidas, indexado pela
    chave de idempotencia enviada pelo cliente."""

    def __init__(self):
        self._resultados = {}
        self._lock = threading.Lock()

    def reservar(self, chave: str) -> tuple[str, dict | None]:
        """Reserva a chave de forma atomica. Devolve ("reservada", None) se esta
        chamada passou a ser a dona da chave, ("em_andamento", None) se outra
        requisicao ja a esta processando, ou ("concluida", resultado)."""
        with self._lock:
            atual = self._resultados.get(chave)
            if atual is None:
                self._resultados[chave] = _EM_ANDAMENTO
                return "reservada", None
            if atual is _EM_ANDAMENTO:
                return "em_andamento", None
            return "concluida", atual

    def liberar(self, chave: str) -> None:
        with self._lock:
            if self._resultados.get(chave) is _EM_ANDAMENTO:
                del self._resultados[chave]

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
