import { chamarApi } from "../services/api";
import { useSessao } from "./useSessao";
import { useMensagem } from "./useMensagem";

export function useContaApi() {
  const { estado, encerrar } = useSessao();
  const { mostrar } = useMensagem();

  async function chamarAutenticado(caminho, opcoes = {}) {
    try {
      return await chamarApi(estado.sessao.agenciaUrl, caminho, { ...opcoes, token: estado.sessao.token });
    } catch (erro) {
      if (erro.status === 401) {
        encerrar();
        mostrar("Sessão expirada. Faça login novamente.", "erro");
      }
      throw erro;
    }
  }

  return { chamarAutenticado };
}
