<script setup lang="ts">
/**
 * Checkbox Component
 * Based on: UXD-00 Design Foundations
 */

import { computed } from 'vue'

// Props
interface Props {
  modelValue?: boolean
  id?: string
  disabled?: boolean
  error?: string
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: false,
  disabled: false,
})

// Emits
const emit = defineEmits<{
  'update:modelValue': [value: boolean]
}>()

// Computed
const hasError = computed(() => !!props.error)

// Methods
function handleChange(event: Event) {
  const target = event.target as HTMLInputElement
  emit('update:modelValue', target.checked)
}
</script>

<template>
  <div class="flex items-start gap-2">
    <input
      :id="id"
      type="checkbox"
      :checked="modelValue"
      :disabled="disabled"
      :aria-invalid="hasError"
      :aria-describedby="error ? `${id}-error` : undefined"
      class="mt-0.5 w-4 h-4 text-primary border-border rounded focus:ring-2 focus:ring-primary focus:ring-offset-0 disabled:opacity-50 disabled:cursor-not-allowed"
      @change="handleChange"
    />
    <div class="flex-1">
      <label
        v-if="$slots.default"
        :for="id"
        class="text-sm text-text-primary cursor-pointer select-none"
      >
        <slot />
      </label>
      <p v-if="error" :id="`${id}-error`" class="mt-1 text-xs text-danger">
        {{ error }}
      </p>
    </div>
  </div>
</template>
