<script setup>
import { computed, ref } from "vue";
import { RouterLink, useRouter } from "vue-router";
import { chamarApi } from "../services/api";
import { agenciaDaConta } from "../services/agencias";
import { criarConta } from "../services/contas";
import { useSessao } from "../composables/useSessao";
import { useMensagem } from "../composables/useMensagem";
import AuthCard from "../components/ui/AuthCard.vue";

const router = useRouter();
const { iniciar } = useSessao();
const { mostrar, limpar } = useMensagem();

const nome = ref("");
const senha = ref("");
const confirmacao = ref("");
const numero = ref("");
const carregando = ref(false);

const agencia = computed(() => (numero.value ? agenciaDaConta(numero.value) : null));

async function abrirConta() {
  if (senha.value !== confirmacao.value) {
    mostrar("As senhas não conferem.", "erro");
    return;
  }
  carregando.value = true;
  try {
    const { id, agencia: agenciaConta } = await criarConta({
      nome: nome.value,
      senha: senha.value,
      numero: numero.value,
    });
    try {
      const login = await chamarApi(agenciaConta.url, "/auth/login", {
        metodo: "POST",
        corpo: { id, senha: senha.value },
      });
      iniciar({ token: login.accessToken, contaId: id, agenciaUrl: agenciaConta.url });
    } catch {
      mostrar(`Conta ${id} criada, mas o login automático falhou. Entre com o número e a senha.`, "erro");
      router.push("/entrar");
      return;
    }
    limpar();
    mostrar(`Conta ${id} criada na ${agenciaConta.nome}. Bem-vindo ao ICEIBank!`, "sucesso");
    router.push("/painel");
  } catch (erro) {
    mostrar(erro.status === 409 ? "Este número de conta já está em uso." : erro.message, "erro");
  } finally {
    carregando.value = false;
  }
}
</script>

<template>
  <AuthCard titulo="Abra sua conta ICEIBank" subtitulo="Sem papelada, sem fila, sem anuidade.">
    <form @submit.prevent="abrirConta">
      <label class="field">
        <span>Nome completo</span>
        <input v-model="nome" type="text" minlength="3" placeholder="Ex.: Laura Pontara" required autofocus />
      </label>
      <label class="field">
        <span>Senha</span>
        <input v-model="senha" type="password" minlength="4" autocomplete="new-password" required />
      </label>
      <label class="field">
        <span>Confirmar senha</span>
        <input v-model="confirmacao" type="password" autocomplete="new-password" required />
      </label>
      <label class="field">
        <span>Número da conta (opcional)</span>
        <input v-model="numero" type="number" min="0" step="1" placeholder="Deixe em branco para gerar automaticamente" />
      </label>
      <p v-if="agencia" class="muted dica">Esta conta ficará na {{ agencia.nome }}.</p>
      <button type="submit" class="btn-primary btn-block" :disabled="carregando">
        {{ carregando ? "Criando conta..." : "Criar minha conta" }}
      </button>
    </form>
    <template #rodape>
      Já tem conta? <RouterLink to="/entrar">Acessar painel</RouterLink>
    </template>
  </AuthCard>
</template>

<style scoped>
.dica {
  margin-top: 8px;
  font-size: 12px;
}
</style>
