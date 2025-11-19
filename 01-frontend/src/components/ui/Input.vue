<script setup lang="ts">
/**
 * Input Component
 * Based on: UXD-00 Design Foundations
 */

import { computed } from 'vue'
import { cn } from '@/lib/utils'

// Props
interface Props {
  modelValue?: string | number
  type?: 'text' | 'email' | 'password' | 'tel' | 'number' | 'url'
  placeholder?: string
  disabled?: boolean
  error?: string
  helperText?: string
  prefix?: string
  suffix?: string
  id?: string
}

const props = withDefaults(defineProps<Props>(), {
  type: 'text',
  disabled: false
})

// Emits
const emit = defineEmits<{
  'update:modelValue': [value: string | number]
}>()

// Computed
const hasError = computed(() => !!props.error)

const inputClasses = computed(() => {
  const baseClasses =
    'w-full px-3 py-2.5 border rounded text-sm transition-colors focus:outline-none focus:ring-1 disabled:opacity-50 disabled:cursor-not-allowed disabled:bg-surface'

  const stateClasses = hasError.value
    ? 'border-danger focus:border-danger focus:ring-danger'
    : 'border-border focus:border-primary focus:ring-primary'

  const prefixPadding = props.prefix ? 'pl-8' : ''
  const suffixPadding = props.suffix ? 'pr-8' : ''

  return cn(baseClasses, stateClasses, prefixPadding, suffixPadding)
})

// Methods
function handleInput(event: Event) {
  const target = event.target as HTMLInputElement
  emit('update:modelValue', props.type === 'number' ? Number(target.value) : target.value)
}
</script>

<template>
  <div class="relative">
    <!-- Prefix -->
    <span
      v-if="prefix"
      class="absolute left-3 top-1/2 -translate-y-1/2 text-text-secondary text-sm pointer-events-none"
    >
      {{ prefix }}
    </span>

    <!-- Input -->
    <input
      :id="id"
      :type="type"
      :value="modelValue"
      :placeholder="placeholder"
      :disabled="disabled"
      :class="inputClasses"
      :aria-invalid="hasError"
      :aria-describedby="error ? `${id}-error` : helperText ? `${id}-helper` : undefined"
      @input="handleInput"
    />

    <!-- Suffix -->
    <span
      v-if="suffix"
      class="absolute right-3 top-1/2 -translate-y-1/2 text-text-secondary text-sm pointer-events-none"
    >
      {{ suffix }}
    </span>

    <!-- Helper Text -->
    <p v-if="helperText && !error" :id="`${id}-helper`" class="mt-1 text-xs text-text-secondary">
      {{ helperText }}
    </p>

    <!-- Error Message -->
    <p v-if="error" :id="`${id}-error`" class="mt-1 text-xs text-danger">
      {{ error }}
    </p>
  </div>
</template>
