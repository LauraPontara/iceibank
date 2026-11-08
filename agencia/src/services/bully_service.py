import threading
import time

import requests

import config

TIMEOUT_S = 1
INTERVALO_HEARTBEAT_S = 3


class ServicoBully:
    """Eleicao de lider pelo algoritmo de Bully: vence a agencia de maior id entre
    as ativas. O estado e protegido por lock porque as rotas HTTP e a propria
    eleicao rodam em threads diferentes."""

    def __init__(self, id_agencia, relogio, registro):
        self.id_agencia = id_agencia
        self.relogio = relogio
        self.registro = registro
        self._lider_atual = None
        self._eleicao_em_andamento = False
        self._lock = threading.Lock()

    def _agencias_com_id_maior(self):
        return [a for a in config.AGENCIAS if a["id"] > self.id_agencia]

    def iniciar_eleicao(self):
        with self._lock:
            if self._eleicao_em_andamento:
                return
            self._eleicao_em_andamento = True

        try:
            self.registro.registrar("ELEICAO_INICIADA", self.relogio.evento_local(), {"idAgencia": self.id_agencia})
            alguem_respondeu = False
            for agencia in self._agencias_com_id_maior():
                try:
                    resposta = requests.post(
                        f"{agencia['url']}/bully/eleicao",
                        json={"origemId": self.id_agencia, "vetorEnvio": self.relogio.ao_enviar()},
                        timeout=TIMEOUT_S,
                    )
                    resposta.raise_for_status()
                    alguem_respondeu = True
                except requests.exceptions.RequestException:
                    # Agencia fora do ar ou nao respondeu a tempo: ignora e segue
                    pass
        finally:
            with self._lock:
                self._eleicao_em_andamento = False

        # Se alguem maior respondeu, e essa agencia quem conduz a propria eleicao
        # e anuncia o resultado via /bully/coordenador.
        if not alguem_respondeu:
            self._tornar_me_lider()

    def _tornar_me_lider(self):
        with self._lock:
            # Uma agencia maior pode ter se anunciado enquanto esta eleicao rodava
            if self._lider_atual is not None and self._lider_atual > self.id_agencia:
                return
            self._lider_atual = self.id_agencia

        self.registro.registrar("TORNOU_LIDER", self.relogio.evento_local(), {"idAgencia": self.id_agencia})
        for agencia in config.AGENCIAS:
            if agencia["id"] == self.id_agencia:
                continue
            try:
                requests.post(
                    f"{agencia['url']}/bully/coordenador",
                    json={"liderId": self.id_agencia, "vetorEnvio": self.relogio.ao_enviar()},
                    timeout=TIMEOUT_S,
                )
            except requests.exceptions.RequestException:
                # Agencia fora do ar: descobre a lider quando voltar
                pass

    def receber_eleicao(self, origem_id, vetor_recebido):
        vetor = self.relogio.ao_receber(vetor_recebido)
        self.registro.registrar("ELEICAO_RECEBIDA", vetor, {"de": origem_id, "minhaId": self.id_agencia})
        # O 200 da rota ja e o "OK" implicito. A eleicao propria roda em outra thread
        # para a resposta sair antes do timeout de quem chamou.
        threading.Thread(target=self.iniciar_eleicao, daemon=True).start()

    def receber_coordenador(self, lider_id, vetor_recebido):
        vetor = self.relogio.ao_receber(vetor_recebido)
        with self._lock:
            lider_conhecido = self._lider_atual

        # Anuncios atrasados de uma agencia menor nao derrubam uma lider maior que continua viva
        if lider_conhecido is not None and lider_id < lider_conhecido and self._agencia_responde(lider_conhecido):
            return

        with self._lock:
            self._lider_atual = lider_id
        self.registro.registrar("LIDER_ANUNCIADO", vetor, {"liderId": lider_id, "agencia": self.id_agencia})

    def _agencia_responde(self, id_agencia):
        if id_agencia == self.id_agencia:
            return True
        agencia = next(a for a in config.AGENCIAS if a["id"] == id_agencia)
        try:
            requests.get(f"{agencia['url']}/bully/lider", timeout=TIMEOUT_S).raise_for_status()
            return True
        except requests.exceptions.RequestException:
            return False

    def obter_lider_atual(self):
        with self._lock:
            return self._lider_atual

    def verificar_lider(self):
        lider = self.obter_lider_atual()
        if lider is None:
            self.iniciar_eleicao()
            return
        if lider == self.id_agencia:
            return

        if self._agencia_responde(lider):
            return

        self.registro.registrar("LIDER_NAO_RESPONDEU", self.relogio.evento_local(), {"liderAtual": lider, "agencia": self.id_agencia})
        with self._lock:
            # So esquece a lider antiga se nenhum anuncio novo chegou durante a verificacao
            if self._lider_atual == lider:
                self._lider_atual = None
        self.iniciar_eleicao()

    def iniciar_heartbeat(self, intervalo_s=INTERVALO_HEARTBEAT_S):
        def laco():
            while True:
                time.sleep(intervalo_s)
                try:
                    self.verificar_lider()
                except Exception as erro:
                    print(f"[bully] falha no heartbeat: {erro!r}")

        threading.Thread(target=laco, name=f"heartbeat-agencia-{self.id_agencia}", daemon=True).start()
