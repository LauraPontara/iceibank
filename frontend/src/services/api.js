export async function chamarApi(agenciaUrl, caminho, { metodo = "GET", corpo = null, token = null } = {}) {
  const cabecalhos = { "Content-Type": "application/json" };
  if (token) cabecalhos["Authorization"] = `Bearer ${token}`;

  let resposta;
  try {
    resposta = await fetch(`${agenciaUrl}${caminho}`, {
      method: metodo,
      headers: cabecalhos,
      body: corpo ? JSON.stringify(corpo) : undefined,
    });
  } catch {
    const erro = new Error(`Não foi possível contatar a agência em ${agenciaUrl}. Ela está no ar?`);
    erro.status = 0;
    throw erro;
  }

  const dados = await resposta.json().catch(() => ({}));

  if (!resposta.ok) {
    const detalhe = Array.isArray(dados.detail) ? "Dados inválidos. Confira os campos." : dados.detail;
    const erro = new Error(detalhe || `Erro ${resposta.status}`);
    erro.status = resposta.status;
    throw erro;
  }
  return dados;
}
