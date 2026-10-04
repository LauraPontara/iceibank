import { AGENCIAS } from "./agencias";
import { chamarApi } from "./api";

// O token de administrador e valido em todas as agencias (mesma chave JWT),
// entao basta autenticar em qualquer uma que esteja no ar.
export async function loginAdmin(usuario, senha) {
  let ultimoErro = null;
  for (const agencia of AGENCIAS) {
    try {
      const resposta = await chamarApi(agencia.url, "/auth/admin/login", {
        metodo: "POST",
        corpo: { usuario, senha },
      });
      return resposta.accessToken;
    } catch (erro) {
      if (erro.status !== 0 && erro.status < 500) throw erro;
      ultimoErro = erro;
    }
  }
  throw ultimoErro ?? new Error("Nenhuma agência disponível.");
}

export async function carregarAgencia(agencia, token) {
  const [status, contas] = await Promise.all([
    chamarApi(agencia.url, "/admin/status", { token }),
    chamarApi(agencia.url, "/admin/contas", { token }),
  ]);
  return { agencia, online: true, status, contas };
}
