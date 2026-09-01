export async function chamarApi(agenciaUrl, caminho, { metodo = "GET", corpo = null, token = null } = {}) {
  const cabecalhos = { "Content-Type": "application/json" };
  if (token) cabecalhos["Authorization"] = `Bearer ${token}`;

  const resposta = await fetch(`${agenciaUrl}${caminho}`, {
    method: metodo,
    headers: cabecalhos,
    body: corpo ? JSON.stringify(corpo) : undefined,
  });

  const dados = await resposta.json().catch(() => ({}));

  if (!resposta.ok) {
    const erro = new Error(dados.detail || `Erro ${resposta.status}`);
    erro.status = resposta.status;
    throw erro;
  }
  return dados;
}
