<script setup>
import { ref } from "vue";
import { Eye, EyeOff } from "lucide-vue-next";

defineProps({
  label: { type: String, required: true },
  autocomplete: { type: String, default: "current-password" },
  minlength: { type: [Number, String], default: undefined },
  placeholder: { type: String, default: "" },
  autofocus: { type: Boolean, default: false },
});

const modelo = defineModel({ type: String, default: "" });
const visivel = ref(false);
</script>

<template>
  <label class="field">
    <span>{{ label }}</span>
    <div class="campo-senha">
      <input
        v-model="modelo"
        :type="visivel ? 'text' : 'password'"
        :autocomplete="autocomplete"
        :minlength="minlength"
        :placeholder="placeholder"
        :autofocus="autofocus"
        required
      />
      <button
        type="button"
        class="olho"
        :aria-label="visivel ? 'Ocultar senha' : 'Mostrar senha'"
        :aria-pressed="visivel"
        @click="visivel = !visivel"
      >
        <EyeOff v-if="visivel" :size="18" />
        <Eye v-else :size="18" />
      </button>
    </div>
  </label>
</template>

<style scoped>
.campo-senha {
  position: relative;
}

.campo-senha input {
  padding-right: 48px;
}

.olho {
  position: absolute;
  top: 50%;
  right: 8px;
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  border: 0;
  border-radius: 10px;
  background: transparent;
  color: var(--muted-foreground);
  cursor: pointer;
  transform: translateY(-50%);
  transition: color 0.2s ease, background-color 0.2s ease;
}

.olho:hover {
  color: var(--foreground);
  background: var(--secondary);
}
</style>
