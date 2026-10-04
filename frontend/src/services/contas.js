import { chamarApi } from "./api";
import { agenciaDaConta } from "./agencias";

const MAX_TENTATIVAS = 8;

function numeroAleatorio() {
  return Math.floor(1000 + Math.random() * 9000);
}

async function criarComId(id, { nome, senha, saldoInicial }) {
  const agencia = agenciaDaConta(id);
  await chamarApi(agencia.url, "/contas", {
    metodo: "POST",
    corpo: { id, nomeAluno: nome.trim(), senha, saldoInicial },
  });
  return { id, agencia };
}

// Sem numero informado, sorteia um numero livre (tentando de novo em caso de conflito).
export async function criarConta({ nome, senha, saldoInicial = 0, numero = null }) {
  const dados = { nome, senha, saldoInicial };
  if (numero !== null && numero !== "") return criarComId(Number(numero), dados);

  for (let tentativa = 0; tentativa < MAX_TENTATIVAS; tentativa++) {
    try {
      return await criarComId(numeroAleatorio(), dados);
    } catch (erro) {
      if (erro.status !== 409) throw erro;
    }
  }
  throw new Error("Não foi possível gerar um número de conta livre. Tente novamente.");
}
