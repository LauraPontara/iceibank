<script setup>
import { ref } from "vue";
import { useSessao } from "../composables/useSessao";
import { useContaApi } from "../composables/useContaApi";
import { useMensagem } from "../composables/useMensagem";
import DepositoForm from "./DepositoForm.vue";
import SaqueForm from "./SaqueForm.vue";
import TransferenciaForm from "./TransferenciaForm.vue";

const { estado, encerrar } = useSessao();
const { chamarAutenticado } = useContaApi();
const { mostrar } = useMensagem();
const saldo = ref(null);

async function consultarSaldo() {
  try {
    const conta = await chamarAutenticado(`/contas/${estado.sessao.contaId}`);
    saldo.value = conta.saldo;
  } catch (erro) {
    mostrar(erro.message, "erro");
  }
}

function aoAtualizarSaldo(novoSaldo) {
  saldo.value = novoSaldo;
}
</script>

<template>
  <section>
    <h2>Conta {{ estado.sessao.contaId }}</h2>
    <button class="sair" @click="encerrar">Sair</button>
    <button @click="consultarSaldo">Consultar saldo</button>
    <p>Saldo atual: <strong>{{ saldo ?? "-" }}</strong></p>

    <DepositoForm @saldo-atualizado="aoAtualizarSaldo" />
    <SaqueForm @saldo-atualizado="aoAtualizarSaldo" />
    <TransferenciaForm />
  </section>
</template>
