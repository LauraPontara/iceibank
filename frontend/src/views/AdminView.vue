<script setup>
import { onMounted } from "vue";
import { useRouter } from "vue-router";
import { RefreshCw } from "lucide-vue-next";
import { useSessao } from "../composables/useSessao";
import { useAdminDados } from "../composables/useAdminDados";
import { useMensagem } from "../composables/useMensagem";
import AdminStatusAgencias from "../components/admin/AdminStatusAgencias.vue";
import AdminContasTabela from "../components/admin/AdminContasTabela.vue";
import AdminNovaContaForm from "../components/admin/AdminNovaContaForm.vue";
import AdminTransferenciaForm from "../components/admin/AdminTransferenciaForm.vue";

const router = useRouter();
const { estado: sessao, encerrar } = useSessao();
const { estado, contas, recarregar } = useAdminDados();
const { mostrar } = useMensagem();

async function atualizar() {
  if ((await recarregar()) === "expirada") {
    encerrar();
    router.replace("/admin/entrar");
    mostrar("Sessão de administrador expirada. Entre novamente.", "erro");
  }
}

onMounted(atualizar);
</script>

<template>
  <main v-if="sessao.sessao" class="container admin">
    <header class="topo">
      <div>
        <p class="eyebrow">Administrador · {{ sessao.sessao.usuario }}</p>
        <h1>Painel de operações</h1>
      </div>
      <button type="button" class="btn-ghost atualizar" :disabled="estado.carregando" @click="atualizar">
        <RefreshCw :size="14" :class="{ girando: estado.carregando }" /> Atualizar
      </button>
    </header>

    <section class="bloco">
      <AdminStatusAgencias :agencias="estado.agencias" />
    </section>

    <div class="grade">
      <div class="coluna">
        <section class="surface">
          <h2>Nova conta</h2>
          <p class="muted nota">Cria a conta direto na agência responsável (id % 3).</p>
          <AdminNovaContaForm @criada="atualizar" />
        </section>
        <section class="surface">
          <h2>Transferência entre contas</h2>
          <p class="muted nota">Move saldo entre quaisquer contas, mesmo de agências diferentes.</p>
          <AdminTransferenciaForm :contas="contas" @concluida="atualizar" />
        </section>
      </div>

      <section class="surface contas">
        <h2>Contas</h2>
        <p class="muted nota">{{ contas.length }} conta(s) nas agências online. Depósito e saque usam o valor da linha.</p>
        <AdminContasTabela :contas="contas" @alterado="atualizar" />
      </section>
    </div>
  </main>
</template>

<style scoped>
.admin {
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

h2 {
  font-size: 18px;
}

.nota {
  margin: 4px 0 20px;
  font-size: 12px;
}

.atualizar {
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

.bloco {
  margin-top: 32px;
}

.grade {
  display: grid;
  gap: 16px;
  margin-top: 16px;
}

.coluna {
  display: grid;
  gap: 16px;
  align-content: start;
}

@media (min-width: 1024px) {
  .grade {
    grid-template-columns: 5fr 7fr;
    align-items: start;
  }
}

@media (prefers-reduced-motion: reduce) {
  .girando {
    animation: none;
  }
}
</style>
