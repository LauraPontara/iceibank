import { reactive } from "vue";

const DURACAO_MS = 5000;
const estado = reactive({ texto: null, tipo: "erro" });
let temporizador = null;

export function useMensagem() {
  function limpar() {
    clearTimeout(temporizador);
    estado.texto = null;
  }
  function mostrar(texto, tipo = "erro") {
    clearTimeout(temporizador);
    estado.texto = texto;
    estado.tipo = tipo;
    temporizador = setTimeout(limpar, DURACAO_MS);
  }
  return { estado, mostrar, limpar };
}
