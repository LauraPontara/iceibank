# Frontend do ICEIBank

Interface web em Vue 3 + Vite que consome as 3 agências REST do Sprint 1.

## Rodando

```bash
npm install
npm run dev
```

As agências precisam estar no ar nas portas `4030`, `4031` e `4032` (ver `agencia/`). A porta base pode ser trocada com a variável `VITE_PORTA_BASE`.

## Telas

- `/` página inicial com o cartão metal 3D.
- `/abrir-conta` cria a conta direto pela interface. O número é gerado automaticamente (ou informado) e determina a agência por `id % 3`.
- `/entrar` login por número da conta e senha. A agência é escolhida automaticamente, mas pode ser forçada.
- `/painel` saldo, depósito, saque, transferência (local ou entre agências) e atividade recente.

## Estrutura

- `src/views` telas (uma por rota).
- `src/components` formulários de operação e lista de atividade.
- `src/components/ui` blocos visuais reutilizáveis (cartão 3D, fundo animado, cabeçalho).
- `src/composables` estado compartilhado (sessão, mensagens, tema, atividade).
- `src/services` acesso à API, formatação e mapa de agências.
- `src/styles` tokens e estilos do design system.

O design system está documentado em [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md).
