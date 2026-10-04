import { reactive, watch } from "vue";

const CHAVE = "iceibank_atividade";
const LIMITE = 20;

function carregar() {
  try {
    return JSON.parse(localStorage.getItem(CHAVE)) ?? {};
  } catch {
    return {};
  }
}

const estado = reactive({ porConta: carregar() });

watch(
  () => estado.porConta,
  (valor) => localStorage.setItem(CHAVE, JSON.stringify(valor)),
  { deep: true }
);

export function useAtividade() {
  function registrar(contaId, item) {
    const lista = estado.porConta[contaId] ?? [];
    lista.unshift({ ...item, em: new Date().toISOString() });
    estado.porConta[contaId] = lista.slice(0, LIMITE);
  }
  function listar(contaId) {
    return estado.porConta[contaId] ?? [];
  }
  return { registrar, listar };
}
