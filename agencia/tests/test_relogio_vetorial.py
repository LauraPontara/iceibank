import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "src"))

from services.relogio_vetorial import RelogioVetorial, comparar_vetores


class TestRelogioVetorial(unittest.TestCase):
    def test_evento_local_incrementa_so_a_propria_posicao(self):
        relogio = RelogioVetorial(1, 3)
        self.assertEqual(relogio.evento_local(), [0, 1, 0])
        self.assertEqual(relogio.evento_local(), [0, 2, 0])

    def test_ao_enviar_incrementa_e_devolve_o_vetor_inteiro(self):
        relogio = RelogioVetorial(0, 3)
        relogio.evento_local()
        self.assertEqual(relogio.ao_enviar(), [2, 0, 0])

    def test_ao_receber_faz_maximo_por_posicao_e_incrementa_a_propria(self):
        relogio = RelogioVetorial(1, 3)
        relogio.evento_local()
        self.assertEqual(relogio.ao_receber([4, 0, 2]), [4, 2, 2])

    def test_ao_receber_nao_diminui_posicoes_ja_maiores(self):
        relogio = RelogioVetorial(2, 3)
        for _ in range(5):
            relogio.evento_local()
        self.assertEqual(relogio.ao_receber([1, 1, 1]), [1, 1, 6])

    def test_vetor_devolvido_nao_compartilha_estado_com_o_relogio(self):
        relogio = RelogioVetorial(0, 2)
        copia = relogio.evento_local()
        copia[0] = 99
        self.assertEqual(relogio.atual(), [1, 0])


class TestCompararVetores(unittest.TestCase):
    def test_antes_quando_todas_as_posicoes_sao_menores_ou_iguais(self):
        self.assertEqual(comparar_vetores([3, 1, 0], [3, 2, 0]), "ANTES")

    def test_depois_e_o_inverso_de_antes(self):
        self.assertEqual(comparar_vetores([3, 2, 0], [3, 1, 0]), "DEPOIS")

    def test_concorrentes_quando_nenhum_domina_o_outro(self):
        self.assertEqual(comparar_vetores([3, 1, 0], [1, 3, 0]), "CONCORRENTES")

    def test_iguais(self):
        self.assertEqual(comparar_vetores([1, 2, 3], [1, 2, 3]), "IGUAIS")

    def test_debito_causalmente_antes_do_credito_remoto(self):
        agencia_0 = RelogioVetorial(0, 3)
        agencia_1 = RelogioVetorial(1, 3)
        debito = agencia_0.evento_local()
        envio = agencia_0.ao_enviar()
        credito = agencia_1.ao_receber(envio)
        self.assertEqual(comparar_vetores(debito, credito), "ANTES")

    def test_criacoes_independentes_em_agencias_diferentes_sao_concorrentes(self):
        agencia_0 = RelogioVetorial(0, 3)
        agencia_1 = RelogioVetorial(1, 3)
        self.assertEqual(comparar_vetores(agencia_0.evento_local(), agencia_1.evento_local()), "CONCORRENTES")


if __name__ == "__main__":
    unittest.main()
