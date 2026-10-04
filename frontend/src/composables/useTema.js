import { ref } from "vue";

const CHAVE = "iceibank_tema";
const tema = ref(document.documentElement.dataset.theme || "dark");

function aplicar(valor) {
  tema.value = valor;
  document.documentElement.dataset.theme = valor;
  try {
    localStorage.setItem(CHAVE, valor);
  } catch {
    // armazenamento indisponivel: o tema vale so para esta sessao
  }
}

export function useTema() {
  function alternar() {
    aplicar(tema.value === "dark" ? "light" : "dark");
  }
  return { tema, alternar };
}
