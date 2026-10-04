import threading


class RelogioVetorial:
    """Relogio vetorial com uma posicao por agencia. Protegido por lock porque
    o consumidor de mensagens roda em outra thread, em paralelo ao servidor HTTP."""

    def __init__(self, id_agencia, numero_agencias):
        self.id_agencia = id_agencia
        self.vetor = [0] * numero_agencias
        self._lock = threading.Lock()

    def evento_local(self):
        with self._lock:
            self.vetor[self.id_agencia] += 1
            return list(self.vetor)

    def ao_enviar(self):
        with self._lock:
            self.vetor[self.id_agencia] += 1
            return list(self.vetor)

    def ao_receber(self, vetor_recebido):
        with self._lock:
            for i in range(len(self.vetor)):
                self.vetor[i] = max(self.vetor[i], vetor_recebido[i])
            self.vetor[self.id_agencia] += 1
            return list(self.vetor)

    def atual(self):
        with self._lock:
            return list(self.vetor)


def comparar_vetores(v1, v2):
    """Devolve ANTES, DEPOIS, IGUAIS ou CONCORRENTES para os eventos de v1 e v2."""
    v1_menor_ou_igual = all(a <= b for a, b in zip(v1, v2))
    v2_menor_ou_igual = all(b <= a for a, b in zip(v1, v2))
    if v1_menor_ou_igual and v2_menor_ou_igual:
        return "IGUAIS"
    if v1_menor_ou_igual:
        return "ANTES"
    if v2_menor_ou_igual:
        return "DEPOIS"
    return "CONCORRENTES"
