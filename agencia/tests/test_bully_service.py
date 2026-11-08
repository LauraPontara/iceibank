import os
import sys
import unittest
from unittest.mock import MagicMock, patch

import requests

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "src"))

from services.bully_service import ServicoBully
from services.relogio_vetorial import RelogioVetorial


def criar_servico(id_agencia):
    return ServicoBully(id_agencia, RelogioVetorial(id_agencia, 3), MagicMock())


def recusar_conexao(*_args, **_kwargs):
    raise requests.exceptions.ConnectionError()


class TestEleicao(unittest.TestCase):
    @patch("services.bully_service.requests.post", side_effect=recusar_conexao)
    def test_vence_quando_nenhuma_agencia_maior_responde(self, _post):
        servico = criar_servico(1)
        servico.iniciar_eleicao()
        self.assertEqual(servico.obter_lider_atual(), 1)

    @patch("services.bully_service.requests.post")
    def test_nao_se_declara_lider_quando_uma_agencia_maior_responde(self, _post):
        servico = criar_servico(0)
        servico.iniciar_eleicao()
        self.assertIsNone(servico.obter_lider_atual())

    @patch("services.bully_service.requests.post")
    def test_maior_id_nao_pergunta_a_ninguem_e_vence(self, post):
        servico = criar_servico(2)
        servico.iniciar_eleicao()
        self.assertEqual(servico.obter_lider_atual(), 2)
        urls = [chamada.args[0] for chamada in post.call_args_list]
        self.assertTrue(all(url.endswith("/bully/coordenador") for url in urls))

    @patch("services.bully_service.requests.post", side_effect=recusar_conexao)
    def test_nao_assume_se_uma_agencia_maior_se_anunciou_durante_a_eleicao(self, _post):
        servico = criar_servico(1)
        servico.receber_coordenador(2, [0, 0, 1])
        servico._tornar_me_lider()
        self.assertEqual(servico.obter_lider_atual(), 2)


class TestAnuncioDeCoordenador(unittest.TestCase):
    @patch("services.bully_service.requests.get")
    def test_anuncio_atrasado_nao_derruba_lider_maior_que_esta_viva(self, _get):
        servico = criar_servico(0)
        servico.receber_coordenador(2, [0, 0, 1])
        servico.receber_coordenador(1, [0, 1, 0])
        self.assertEqual(servico.obter_lider_atual(), 2)

    @patch("services.bully_service.requests.get", side_effect=recusar_conexao)
    def test_aceita_lider_menor_quando_a_antiga_caiu(self, _get):
        servico = criar_servico(0)
        servico.receber_coordenador(2, [0, 0, 1])
        servico.receber_coordenador(1, [0, 1, 0])
        self.assertEqual(servico.obter_lider_atual(), 1)


class TestHeartbeat(unittest.TestCase):
    @patch("services.bully_service.requests.post", side_effect=recusar_conexao)
    @patch("services.bully_service.requests.get", side_effect=recusar_conexao)
    def test_lider_fora_do_ar_dispara_nova_eleicao(self, _get, _post):
        servico = criar_servico(1)
        servico.receber_coordenador(2, [0, 0, 1])
        servico.verificar_lider()
        self.assertEqual(servico.obter_lider_atual(), 1)
        tipos = [chamada.args[0] for chamada in servico.registro.registrar.call_args_list]
        self.assertIn("LIDER_NAO_RESPONDEU", tipos)

    @patch("services.bully_service.requests.get")
    def test_lider_viva_nao_avanca_o_relogio(self, _get):
        servico = criar_servico(0)
        servico.receber_coordenador(2, [0, 0, 1])
        antes = servico.relogio.atual()
        servico.verificar_lider()
        self.assertEqual(servico.relogio.atual(), antes)


if __name__ == "__main__":
    unittest.main()
