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
  (valor) => {
    try {
      localStorage.setItem(CHAVE, JSON.stringify(valor));
    } catch {
      // cota cheia ou modo privado: o historico vale so nesta sessao
    }
  },
  { deep: true }
);

export function useAtividade() {
  function registrar(contaId, item) {
    const lista = estado.porConta[contaId] ?? [];
    lista.unshift({ ...item, id: crypto.randomUUID(), em: new Date().toISOString() });
    estado.porConta[contaId] = lista.slice(0, LIMITE);
  }
  function listar(contaId) {
    return estado.porConta[contaId] ?? [];
  }
  return { registrar, listar };
}
