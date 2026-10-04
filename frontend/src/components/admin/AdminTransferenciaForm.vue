<script setup>
import { computed, ref, watch } from "vue";
import { useAdminApi } from "../../composables/useAdminApi";
import { useMensagem } from "../../composables/useMensagem";
import { formatarMoeda } from "../../services/formato";

const props = defineProps({ contas: { type: Array, required: true } });
const emit = defineEmits(["concluida"]);

const { chamarAdmin } = useAdminApi();
const { mostrar } = useMensagem();

const origemId = ref("");
const destinoId = ref("");
const valor = ref("");
const carregando = ref(false);
// Mantida entre tentativas para que um reenvio apos falha de rede nao debite duas vezes.
const chaveIdempotencia = ref(crypto.randomUUID());

watch([origemId, destinoId, valor], () => (chaveIdempotencia.value = crypto.randomUUID()));

const origem = computed(() => props.contas.find((c) => c.id === Number(origemId.value)));
const destino = computed(() => props.contas.find((c) => c.id === Number(destinoId.value)));
const entreAgencias = computed(() => origem.value && destino.value && origem.value.agencia.id !== destino.value.agencia.id);

async function transferir() {
  carregando.value = true;
  try {
    const montante = Number(valor.value);
    const resultado = await chamarAdmin(origem.value.agencia.url, "/transferencias", {
      metodo: "POST",
      corpo: {
        idOrigem: origem.value.id,
        idDestino: destino.value.id,
        valor: montante,
        idempotencyKey: chaveIdempotencia.value,
      },
    });
    mostrar(`${resultado.mensagem} ${formatarMoeda(montante)} de ${origem.value.id} para ${destino.value.id}.`, "sucesso");
    valor.value = "";
    emit("concluida");
  } catch (erro) {
    if (!erro.tratado) mostrar(erro.message, "erro");
  } finally {
    carregando.value = false;
  }
}
</script>

<template>
  <form @submit.prevent="transferir">
    <label class="field">
      <span>Conta de origem</span>
      <select v-model="origemId" required>
        <option value="" disabled>Selecione</option>
        <option v-for="c in contas" :key="c.id" :value="c.id">
          {{ c.id }} · {{ c.nomeAluno }} · {{ formatarMoeda(c.saldo) }}
        </option>
      </select>
    </label>
    <label class="field">
      <span>Conta de destino</span>
      <select v-model="destinoId" required>
        <option value="" disabled>Selecione</option>
        <option v-for="c in contas" :key="c.id" :value="c.id" :disabled="c.id === Number(origemId)">
          {{ c.id }} · {{ c.nomeAluno }}
        </option>
      </select>
    </label>
    <p v-if="origem && destino" class="muted rota">
      {{ entreAgencias ? `Entre agências (${origem.agencia.nome} para ${destino.agencia.nome})` : "Mesma agência" }}
    </p>
    <label class="field">
      <span>Valor (R$)</span>
      <input v-model="valor" class="valor" type="number" min="0.01" step="0.01" placeholder="0,00" required />
    </label>
    <button type="submit" class="btn-primary btn-block" :disabled="carregando || contas.length < 2">
      Transferir entre contas
    </button>
    <p v-if="contas.length < 2" class="muted rota">Crie pelo menos duas contas para testar transferências.</p>
  </form>
</template>

<style scoped>
.rota {
  margin-top: 8px;
  font-size: 12px;
}

form .btn-primary {
  margin-top: 20px;
}
</style>
