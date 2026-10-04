import { useRouter } from "vue-router";
import { chamarApi } from "../services/api";
import { useSessao } from "./useSessao";
import { useMensagem } from "./useMensagem";

export function useAdminApi() {
  const { estado, encerrar } = useSessao();
  const { mostrar } = useMensagem();
  const router = useRouter();

  async function chamarAdmin(agenciaUrl, caminho, opcoes = {}) {
    try {
      return await chamarApi(agenciaUrl, caminho, { ...opcoes, token: estado.sessao.token });
    } catch (erro) {
      if (erro.status === 401) {
        encerrar();
        router.replace("/admin/entrar");
        mostrar("Sessão de administrador expirada. Entre novamente.", "erro");
        erro.tratado = true;
      }
      throw erro;
    }
  }

  return { chamarAdmin };
}
