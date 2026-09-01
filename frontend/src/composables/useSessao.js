import { reactive, watch } from "vue";

const CHAVE = "iceibank_sessao";

function carregar() {
  const bruto = localStorage.getItem(CHAVE);
  return bruto ? JSON.parse(bruto) : null;
}

const estado = reactive({ sessao: carregar() });

watch(
  () => estado.sessao,
  (valor) => {
    if (valor) localStorage.setItem(CHAVE, JSON.stringify(valor));
    else localStorage.removeItem(CHAVE);
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
