<script setup>
import { computed, ref } from "vue";
import { criarConta } from "../../services/contas";
import { agenciaDaConta } from "../../services/agencias";
import { formatarMoeda } from "../../services/formato";
import { useMensagem } from "../../composables/useMensagem";

const emit = defineEmits(["criada"]);
const { mostrar } = useMensagem();

const nome = ref("");
const senha = ref("");
const saldoInicial = ref("0");
const numero = ref("");
const carregando = ref(false);

const agencia = computed(() => (numero.value !== "" ? agenciaDaConta(numero.value) : null));

async function criar() {
  carregando.value = true;
  try {
    const { id, agencia: destino } = await criarConta({
      nome: nome.value,
      senha: senha.value,
      saldoInicial: Number(saldoInicial.value) || 0,
      numero: numero.value,
    });
    mostrar(`Conta ${id} criada na ${destino.nome} com ${formatarMoeda(Number(saldoInicial.value) || 0)}.`, "sucesso");
    nome.value = "";
    senha.value = "";
    saldoInicial.value = "0";
    numero.value = "";
    emit("criada");
  } catch (erro) {
    mostrar(erro.status === 409 ? "Este número de conta já está em uso." : erro.message, "erro");
  } finally {
    carregando.value = false;
  }
}
</script>

<template>
  <form @submit.prevent="criar">
    <label class="field">
      <span>Titular</span>
      <input v-model="nome" type="text" minlength="3" placeholder="Nome do titular" required />
    </label>
    <label class="field">
      <span>Senha da conta</span>
      <input v-model="senha" type="text" minlength="4" autocomplete="off" placeholder="Senha de teste" required />
    </label>
    <label class="field">
      <span>Saldo inicial (R$)</span>
      <input v-model="saldoInicial" type="number" min="0" step="0.01" required />
    </label>
    <label class="field">
      <span>Número da conta (opcional)</span>
      <input v-model="numero" type="number" min="0" step="1" placeholder="Em branco para gerar" />
    </label>
    <p v-if="agencia" class="muted dica">Ficará na {{ agencia.nome }}.</p>
    <button type="submit" class="btn-primary btn-block" :disabled="carregando">
      {{ carregando ? "Criando..." : "Criar conta" }}
    </button>
  </form>
</template>

<style scoped>
.dica {
  margin-top: 8px;
  font-size: 12px;
}

form .btn-primary {
  margin-top: 20px;
}
</style>
