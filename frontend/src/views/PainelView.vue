<script setup>
import { computed, onMounted, ref } from "vue";
import { AnimatePresence, motion } from "motion-v";
import { ArrowDownToLine, ArrowUpFromLine, ArrowLeftRight, Copy, Check, RefreshCw } from "lucide-vue-next";
import { useSessao } from "../composables/useSessao";
import { useContaApi } from "../composables/useContaApi";
import { useMensagem } from "../composables/useMensagem";
import { useAtividade } from "../composables/useAtividade";
import { AGENCIAS } from "../services/agencias";
import { formatarMoeda } from "../services/formato";
import MetalCard from "../components/ui/MetalCard.vue";
import DepositoForm from "../components/DepositoForm.vue";
import SaqueForm from "../components/SaqueForm.vue";
import TransferenciaForm from "../components/TransferenciaForm.vue";
import AtividadeLista from "../components/AtividadeLista.vue";

const { estado } = useSessao();
const { chamarAutenticado } = useContaApi();
const { mostrar } = useMensagem();
const { registrar, listar } = useAtividade();

const conta = ref(null);
const aba = ref("deposito");
const copiado = ref(false);
const atualizando = ref(false);

const ABAS = [
  { id: "deposito", rotulo: "Depositar", icone: ArrowDownToLine },
  { id: "saque", rotulo: "Sacar", icone: ArrowUpFromLine },
  { id: "transferencia", rotulo: "Transferir", icone: ArrowLeftRight },
];

const agencia = computed(() => AGENCIAS.find((a) => a.url === estado.sessao?.agenciaUrl));
const atividade = computed(() => listar(estado.sessao?.contaId));
const primeiroNome = computed(() => conta.value?.nomeAluno.split(" ")[0] ?? "");

async function atualizar() {
  atualizando.value = true;
  try {
    conta.value = await chamarAutenticado(`/contas/${estado.sessao.contaId}`);
  } catch (erro) {
    if (!erro.tratado) mostrar(erro.message, "erro");
  } finally {
    atualizando.value = false;
  }
}

function aoConcluir(item) {
  registrar(estado.sessao.contaId, item);
  atualizar();
}

async function copiarNumero() {
  try {
    await navigator.clipboard.writeText(String(estado.sessao.contaId));
    copiado.value = true;
    setTimeout(() => (copiado.value = false), 1500);
  } catch {
    mostrar("Não foi possível copiar o número da conta.", "erro");
  }
}

onMounted(atualizar);
</script>

<template>
  <main class="container painel">
    <header class="topo">
      <div>
        <p class="eyebrow">Olá{{ primeiroNome ? `, ${primeiroNome}` : "" }}</p>
        <h1>Minha conta</h1>
      </div>
      <div class="chips">
        <span class="chip">{{ agencia?.nome }}</span>
        <button type="button" class="chip numero mono" @click="copiarNumero">
          Conta {{ estado.sessao.contaId }}
          <Check v-if="copiado" :size="14" />
          <Copy v-else :size="14" />
        </button>
      </div>
    </header>

    <div class="grade">
      <section class="cartao-coluna">
        <MetalCard
          :titular="conta?.nomeAluno ?? 'Titular'"
          :conta="estado.sessao.contaId"
          :saldo="conta ? formatarMoeda(conta.saldo) : null"
          :valor="conta ? conta.saldo : null"
        />
        <button type="button" class="btn-ghost atualizar" :disabled="atualizando" @click="atualizar">
          <RefreshCw :size="14" :class="{ girando: atualizando }" /> Atualizar saldo
        </button>
      </section>

      <section class="surface operacoes">
        <h2>Movimentar dinheiro</h2>
        <div class="abas" role="tablist">
          <button
            v-for="item in ABAS"
            :key="item.id"
            type="button"
            role="tab"
            :aria-selected="aba === item.id"
            :class="['aba', { ativa: aba === item.id }]"
            @click="aba = item.id"
          >
            <motion.span
              v-if="aba === item.id"
              layout-id="aba-ativa"
              class="pilula"
              :transition="{ type: 'spring', bounce: 0.15, visualDuration: 0.35 }"
            />
            <span class="aba-rotulo"><component :is="item.icone" :size="16" /> {{ item.rotulo }}</span>
          </button>
        </div>
        <AnimatePresence mode="wait" :initial="false">
          <motion.div
            :key="aba"
            :initial="{ opacity: 0, transform: 'translateY(8px)' }"
            :animate="{ opacity: 1, transform: 'translateY(0px)' }"
            :exit="{ opacity: 0, transform: 'translateY(-8px)' }"
            :transition="{ duration: 0.18 }"
          >
            <DepositoForm v-if="aba === 'deposito'" @concluido="aoConcluir" />
            <SaqueForm v-else-if="aba === 'saque'" @concluido="aoConcluir" />
            <TransferenciaForm v-else @concluido="aoConcluir" />
          </motion.div>
        </AnimatePresence>
      </section>
    </div>

    <section class="surface extrato">
      <h2>Atividade recente</h2>
      <p class="muted nota">Operações feitas neste navegador.</p>
      <AtividadeLista :itens="atividade" />
    </section>
  </main>
</template>

<style scoped>
.painel {
  padding-top: 40px;
  padding-bottom: 80px;
}

.topo {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  justify-content: space-between;
  gap: 16px;
}

h1 {
  margin-top: 4px;
  font-size: 32px;
}

.chips {
  display: flex;
  gap: 12px;
}

.numero {
  cursor: pointer;
}

.numero:hover {
  color: var(--foreground);
}

.grade {
  display: grid;
  gap: 16px;
  margin-top: 32px;
}

.grade > * {
  min-width: 0;
}

.cartao-coluna {
  display: flex;
  flex-direction: column;
  justify-content: center;
  gap: 24px;
  padding: 16px 0;
}

.atualizar {
  align-self: center;
  padding: 8px 16px;
  font-size: 13px;
}

.girando {
  animation: gira 0.8s linear infinite;
}

@keyframes gira {
  to {
    transform: rotate(360deg);
  }
}

h2 {
  font-size: 18px;
}

.abas {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
  margin: 20px 0 24px;
  padding: 4px;
  border-radius: 14px;
  background: var(--secondary);
}

.aba {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 10px 12px;
  border: 0;
  border-radius: 10px;
  background: transparent;
  font-size: 14px;
  font-weight: 500;
  color: var(--muted-foreground);
  cursor: pointer;
  transition: color 0.2s ease;
}

.aba:hover {
  color: var(--foreground);
}

.aba.ativa {
  color: var(--primary-foreground);
}

.pilula {
  position: absolute;
  inset: 0;
  border-radius: 10px;
  background: var(--primary);
  box-shadow: 0 8px 24px -10px var(--primary);
}

.aba-rotulo {
  position: relative;
  display: flex;
  align-items: center;
  gap: 8px;
}

.extrato {
  margin-top: 16px;
}

.nota {
  margin: 4px 0 8px;
  font-size: 12px;
}

@media (max-width: 420px) {
  .aba {
    padding: 10px 4px;
    font-size: 13px;
  }

  .aba svg {
    display: none;
  }
}

@media (min-width: 1024px) {
  .grade {
    grid-template-columns: 5fr 7fr;
    align-items: stretch;
  }
}

@media (prefers-reduced-motion: reduce) {
  .girando {
    animation: none;
  }
}
</style>
