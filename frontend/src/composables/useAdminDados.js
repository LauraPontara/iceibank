import { computed, reactive, watch } from "vue";
import { AGENCIAS } from "../services/agencias";
import { carregarAgencia } from "../services/admin";
import { useSessao } from "./useSessao";

const estado = reactive({ agencias: [], carregando: false });
const { estado: sessao } = useSessao();
let ultimaRequisicao = 0;

watch(
  () => sessao.sessao,
  (valor) => {
    if (!valor) estado.agencias = [];
  }
);

const contas = computed(() =>
  estado.agencias
    .filter((a) => a.online)
    .flatMap((a) => a.contas.map((c) => ({ ...c, agencia: a.agencia })))
    .sort((a, b) => a.id - b.id)
);

async function recarregar() {
  const token = sessao.sessao?.token;
  if (!token) return "expirada";

  const requisicao = ++ultimaRequisicao;
  estado.carregando = true;
  const resultados = await Promise.allSettled(AGENCIAS.map((a) => carregarAgencia(a, token)));
  if (requisicao !== ultimaRequisicao) return "ok";

  estado.agencias = resultados.map((r, i) =>
    r.status === "fulfilled"
      ? r.value
      : { agencia: AGENCIAS[i], online: false, status: null, contas: [], erro: r.reason?.message, codigo: r.reason?.status }
  );
  estado.carregando = false;
  return estado.agencias.some((a) => a.codigo === 401) ? "expirada" : "ok";
}

export function useAdminDados() {
  return { estado, contas, recarregar };
}
