<script setup>
import { reactive } from "vue";
import { ArrowDownToLine, ArrowUpFromLine } from "lucide-vue-next";
import { useAdminApi } from "../../composables/useAdminApi";
import { useMensagem } from "../../composables/useMensagem";
import { formatarMoeda } from "../../services/formato";

defineProps({ contas: { type: Array, required: true } });
const emit = defineEmits(["alterado"]);

const { chamarAdmin } = useAdminApi();
const { mostrar } = useMensagem();
const valores = reactive({});
const ocupada = reactive({});

async function operar(conta, operacao) {
  const montante = Number(valores[conta.id]);
  if (!(montante > 0)) {
    mostrar("Informe um valor maior que zero.", "erro");
    return;
  }
  ocupada[conta.id] = true;
  try {
    await chamarAdmin(conta.agencia.url, `/contas/${conta.id}/${operacao}`, {
      metodo: "POST",
      corpo: { valor: montante },
    });
    mostrar(`${operacao === "depositar" ? "Depósito" : "Saque"} de ${formatarMoeda(montante)} na conta ${conta.id}.`, "sucesso");
    valores[conta.id] = "";
    emit("alterado");
  } catch (erro) {
    if (!erro.tratado) mostrar(erro.message, "erro");
  } finally {
    ocupada[conta.id] = false;
  }
}
</script>

<template>
  <p v-if="contas.length === 0" class="muted vazio">Nenhuma conta nas agências online. Crie uma ao lado.</p>
  <div v-else class="rolagem">
    <table>
      <thead>
        <tr>
          <th>Conta</th>
          <th>Titular</th>
          <th>Agência</th>
          <th class="direita">Saldo</th>
          <th>Operar</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="conta in contas" :key="conta.id">
          <td class="mono">{{ conta.id }}</td>
          <td>{{ conta.nomeAluno }}</td>
          <td class="muted">{{ conta.agencia.nome }}</td>
          <td class="direita mono">{{ formatarMoeda(conta.saldo) }}</td>
          <td>
            <div class="operar">
              <input
                v-model="valores[conta.id]"
                type="number"
                min="0.01"
                step="0.01"
                placeholder="0,00"
                :aria-label="`Valor para a conta ${conta.id}`"
              />
              <button type="button" class="btn-secondary icone" :disabled="ocupada[conta.id]" title="Depositar" @click="operar(conta, 'depositar')">
                <ArrowDownToLine :size="14" />
              </button>
              <button type="button" class="btn-secondary icone" :disabled="ocupada[conta.id]" title="Sacar" @click="operar(conta, 'sacar')">
                <ArrowUpFromLine :size="14" />
              </button>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<style scoped>
.vazio {
  font-size: 14px;
}

.rolagem {
  overflow-x: auto;
}

table {
  width: 100%;
  border-collapse: collapse;
  font-size: 14px;
}

th {
  padding: 0 12px 12px;
  font-size: 11px;
  font-weight: 500;
  letter-spacing: 0.15em;
  text-align: left;
  text-transform: uppercase;
  color: var(--muted-foreground);
}

td {
  padding: 12px;
  border-top: 1px solid var(--border);
}

.direita {
  text-align: right;
}

.operar {
  display: flex;
  align-items: center;
  gap: 6px;
}

.operar input {
  width: 96px;
  padding: 8px 10px;
  border: 1px solid var(--input);
  border-radius: 10px;
  background: var(--background);
  outline: none;
}

.operar input:focus {
  border-color: var(--primary);
}

.icone {
  padding: 8px;
  border-radius: 10px;
}
</style>
