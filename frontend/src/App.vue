<script setup>
import { ref } from "vue";
import { useSessao } from "./composables/useSessao";
import { useMensagem } from "./composables/useMensagem";
import LoginView from "./components/LoginView.vue";
import ContaPainel from "./components/ContaPainel.vue";

const { estado: sessaoEstado } = useSessao();
const { estado: mensagemEstado } = useMensagem();
const agenciaUrl = ref(sessaoEstado.sessao?.agenciaUrl ?? "http://localhost:4030");
</script>

<template>
  <header>
    <h1>ICEIBank</h1>
    <div class="agencia-seletor">
      <label for="agenciaUrl">Agência (porta de entrada):</label>
      <select id="agenciaUrl" v-model="agenciaUrl" :disabled="!!sessaoEstado.sessao">
        <option value="http://localhost:4030">Agência 0 (localhost:4030)</option>
        <option value="http://localhost:4031">Agência 1 (localhost:4031)</option>
        <option value="http://localhost:4032">Agência 2 (localhost:4032)</option>
      </select>
    </div>
  </header>

  <main>
    <div v-if="mensagemEstado.texto" :class="['alerta', mensagemEstado.tipo]">{{ mensagemEstado.texto }}</div>

    <LoginView v-if="!sessaoEstado.sessao" :agencia-url="agenciaUrl" />
    <ContaPainel v-else />
  </main>
</template>
