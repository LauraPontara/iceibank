<script setup>
import { ArrowDownToLine, ArrowUpFromLine, ArrowLeftRight } from "lucide-vue-next";
import { formatarDataHora, formatarMoeda } from "../services/formato";

defineProps({ itens: { type: Array, required: true } });

const ROTULOS = { deposito: "Depósito", saque: "Saque", transferencia: "Transferência enviada" };
const ICONES = { deposito: ArrowDownToLine, saque: ArrowUpFromLine, transferencia: ArrowLeftRight };

function negativo(tipo) {
  return tipo !== "deposito";
}
</script>

<template>
  <p v-if="itens.length === 0" class="muted vazio">
    Nenhuma movimentação ainda. Faça um depósito para começar.
  </p>
  <ul v-else class="lista">
    <li v-for="item in itens" :key="item.id ?? item.em" class="linha">
      <span class="icone"><component :is="ICONES[item.tipo]" :size="16" /></span>
      <div class="texto">
        <p class="titulo">{{ ROTULOS[item.tipo] }}</p>
        <p class="detalhe mono muted">
          {{ formatarDataHora(item.em) }}<template v-if="item.contraparte"> · conta {{ item.contraparte }}</template>
        </p>
      </div>
      <span :class="['valor', 'mono', { positivo: !negativo(item.tipo) }]">
        {{ negativo(item.tipo) ? "−" : "+" }} {{ formatarMoeda(item.valor) }}
      </span>
    </li>
  </ul>
</template>

<style scoped>
.vazio {
  font-size: 14px;
}

.lista {
  margin: 0;
  padding: 0;
  list-style: none;
}

.linha {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 0;
}

.linha + .linha {
  border-top: 1px solid var(--border);
}

.icone {
  display: grid;
  place-items: center;
  width: 36px;
  height: 36px;
  border-radius: 12px;
  background: color-mix(in oklch, var(--primary) 10%, transparent);
  color: var(--primary);
}

.texto {
  flex: 1;
}

.titulo {
  font-size: 14px;
  font-weight: 500;
}

.detalhe {
  font-size: 11px;
}

.valor {
  font-size: 14px;
  color: var(--muted-foreground);
}

.valor.positivo {
  color: var(--primary);
}
</style>
