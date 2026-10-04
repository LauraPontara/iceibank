<script setup>
defineProps({ agencias: { type: Array, required: true } });
</script>

<template>
  <ul class="status">
    <li v-for="item in agencias" :key="item.agencia.id" :class="['surface', 'item', { fora: !item.online }]">
      <div class="linha">
        <span :class="['chip', { 'is-off': !item.online }]">{{ item.agencia.nome }}</span>
        <span class="porta mono muted">{{ item.agencia.url.replace("http://", "") }}</span>
      </div>
      <template v-if="item.online">
        <p class="dado"><strong>{{ item.status.totalContas }}</strong> <span class="muted">contas</span></p>
        <p class="lamport mono muted">relógio de Lamport · {{ item.status.relogioLamport }}</p>
      </template>
      <p v-else class="muted offline">Fora do ar{{ item.erro ? `: ${item.erro}` : "" }}</p>
    </li>
  </ul>
</template>

<style scoped>
.status {
  display: grid;
  gap: 16px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.item {
  padding: 20px;
}

.linha {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.porta {
  font-size: 11px;
}

.dado {
  margin-top: 16px;
  font-family: var(--font-display);
  font-size: 28px;
}

.dado span {
  font-family: var(--font-body);
  font-size: 13px;
}

.lamport {
  margin-top: 4px;
  font-size: 11px;
}

.offline {
  margin-top: 16px;
  font-size: 13px;
}

@media (min-width: 768px) {
  .status {
    grid-template-columns: repeat(3, 1fr);
  }
}
</style>
