import { computed, reactive } from "vue";
import { AGENCIAS } from "../services/agencias";
import { carregarAgencia } from "../services/admin";
import { useSessao } from "./useSessao";

const estado = reactive({ agencias: [], carregando: false });

export function useAdminDados() {
  const { estado: sessao } = useSessao();

  const contas = computed(() =>
    estado.agencias
      .filter((a) => a.online)
      .flatMap((a) => a.contas.map((c) => ({ ...c, agencia: a.agencia })))
      .sort((a, b) => a.id - b.id)
  );

  async function recarregar() {
    estado.carregando = true;
    const resultados = await Promise.allSettled(AGENCIAS.map((a) => carregarAgencia(a, sessao.sessao.token)));
    estado.agencias = resultados.map((r, i) =>
      r.status === "fulfilled"
        ? r.value
        : { agencia: AGENCIAS[i], online: false, status: null, contas: [], erro: r.reason?.message, codigo: r.reason?.status }
    );
    estado.carregando = false;
    return estado.agencias.some((a) => a.codigo === 401) ? "expirada" : "ok";
  }

  return { estado, contas, recarregar };
}
