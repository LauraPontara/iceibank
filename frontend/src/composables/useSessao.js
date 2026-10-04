import { reactive, watch } from "vue";

const CHAVE = "iceibank_sessao";

function carregar() {
  try {
    return JSON.parse(localStorage.getItem(CHAVE));
  } catch {
    return null;
  }
}

const estado = reactive({ sessao: carregar() });

watch(
  () => estado.sessao,
  (valor) => {
    try {
      if (valor) localStorage.setItem(CHAVE, JSON.stringify(valor));
      else localStorage.removeItem(CHAVE);
    } catch {
      // armazenamento indisponivel: a sessao vale so ate recarregar a pagina
    }
  },
  { deep: true }
);

export function useSessao() {
  function iniciar(sessao) {
    estado.sessao = sessao;
  }
  function encerrar() {
    estado.sessao = null;
  }
  return { estado, iniciar, encerrar };
}
