const PORTA_BASE = Number(import.meta.env.VITE_PORTA_BASE ?? 4030);

export const AGENCIAS = [0, 1, 2].map((id) => ({
  id,
  nome: `Agência ${id}`,
  url: `http://localhost:${PORTA_BASE + id}`,
}));

export function agenciaDaConta(idConta) {
  return AGENCIAS[Math.abs(Number(idConta)) % AGENCIAS.length];
}
