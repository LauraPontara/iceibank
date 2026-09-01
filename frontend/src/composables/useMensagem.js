import { reactive } from "vue";

const estado = reactive({ texto: null, tipo: "erro" });

export function useMensagem() {
  function mostrar(texto, tipo = "erro") {
    estado.texto = texto;
    estado.tipo = tipo;
  }
  function limpar() {
    estado.texto = null;
  }
  return { estado, mostrar, limpar };
}
