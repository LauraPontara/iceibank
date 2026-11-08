import json
import os
import sys
import unittest
from types import SimpleNamespace
from unittest.mock import MagicMock

from fastapi import HTTPException

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "src"))

from controllers.contas_controller import SincronizarBody, ValorBody, sacar, sincronizar_operacao_pendente
from repositories.conta_repository import ContaRepository
from repositories.idempotencia_repository import IdempotenciaRepository
from services.relogio_vetorial import RelogioVetorial

TOKEN_DONO = {"tipo": "usuario", "sub": "3"}


class TestSincronizacao(unittest.TestCase):
    def setUp(self):
        self.contas = ContaRepository()
        self.contas.criar(3, "Ana", "hash", 100)
        self.contas.criar(6, "Bia", "hash", 0)
        self.relogio = RelogioVetorial(0, 3)
        estado = SimpleNamespace(
            contas=self.contas, relogio=self.relogio, registro=MagicMock(), idempotencia=IdempotenciaRepository(), id_agencia=0
        )
        self.request = SimpleNamespace(app=SimpleNamespace(state=estado))

    def sincronizar(self, token=TOKEN_DONO, **campos):
        campos.setdefault("vetorConhecido", self.relogio.atual())
        return sincronizar_operacao_pendente(3, SincronizarBody(**campos), self.request, token)

    def test_vetor_igual_aplica_e_devolve_o_vetor_novo(self):
        resultado = self.sincronizar(tipo="DEPOSITO", valor=50)
        self.assertEqual(resultado["saldo"], 150)
        self.assertEqual(resultado["vetorAtual"], [1, 0, 0])

    def test_vetor_desatualizado_recusa_com_409_sem_aplicar(self):
        vetor_antigo = self.relogio.atual()
        self.relogio.evento_local()
        resposta = self.sincronizar(tipo="DEPOSITO", valor=50, vetorConhecido=vetor_antigo)
        corpo = json.loads(resposta.body)
        self.assertEqual(resposta.status_code, 409)
        self.assertEqual(corpo["vetorAtual"], [1, 0, 0])
        self.assertEqual(corpo["contaAtual"]["saldo"], 100)
        self.assertNotIn("senhaHash", corpo["contaAtual"])
        self.assertEqual(self.contas.obter(3)["saldo"], 100)

    def test_vetor_concorrente_tambem_e_conflito(self):
        self.relogio.evento_local()
        resposta = self.sincronizar(tipo="DEPOSITO", valor=50, vetorConhecido=[0, 1, 0])
        self.assertEqual(resposta.status_code, 409)

    def test_reenvio_com_a_mesma_chave_nao_aplica_duas_vezes(self):
        vetor = self.relogio.atual()
        primeira = self.sincronizar(tipo="DEPOSITO", valor=50, vetorConhecido=vetor, idempotencyKey="k")
        segunda = self.sincronizar(tipo="DEPOSITO", valor=50, vetorConhecido=vetor, idempotencyKey="k")
        self.assertEqual(primeira, segunda)
        self.assertEqual(self.contas.obter(3)["saldo"], 150)

    def test_conflito_libera_a_chave_para_nova_tentativa(self):
        vetor_antigo = self.relogio.atual()
        self.relogio.evento_local()
        self.sincronizar(tipo="DEPOSITO", valor=50, vetorConhecido=vetor_antigo, idempotencyKey="k")
        resultado = self.sincronizar(tipo="DEPOSITO", valor=50, idempotencyKey="k")
        self.assertEqual(resultado["saldo"], 150)

    def test_saque_com_resposta_perdida_nao_e_aplicado_de_novo_ao_sincronizar(self):
        vetor_do_app = self.relogio.atual()
        sacar(3, ValorBody(valor=40, idempotencyKey="s"), self.request, TOKEN_DONO)
        self.sincronizar(tipo="SAQUE", valor=40, vetorConhecido=vetor_do_app, idempotencyKey="s")
        self.assertEqual(self.contas.obter(3)["saldo"], 60)

    def test_saque_maior_que_o_saldo_nao_avanca_o_relogio(self):
        with self.assertRaises(HTTPException) as erro:
            self.sincronizar(tipo="SAQUE", valor=500)
        self.assertEqual(erro.exception.status_code, 400)
        self.assertEqual(self.relogio.atual(), [0, 0, 0])

    def test_transferencia_local_debita_e_credita(self):
        resultado = self.sincronizar(tipo="TRANSFERENCIA", valor=30, idDestino=6, idempotencyKey="t")
        self.assertEqual(resultado["saldo"], 70)
        self.assertEqual(self.contas.obter(6)["saldo"], 30)
        self.assertEqual(resultado["vetorAtual"], self.relogio.atual())

    def test_tipo_desconhecido_e_recusado(self):
        with self.assertRaises(HTTPException) as erro:
            self.sincronizar(tipo="PIX", valor=1)
        self.assertEqual(erro.exception.status_code, 400)

    def test_conta_de_outra_pessoa_e_proibida(self):
        with self.assertRaises(HTTPException) as erro:
            self.sincronizar(token={"tipo": "usuario", "sub": "9"}, tipo="DEPOSITO", valor=1)
        self.assertEqual(erro.exception.status_code, 403)


if __name__ == "__main__":
    unittest.main()
