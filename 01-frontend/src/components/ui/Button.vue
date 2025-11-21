<script setup lang="ts">
/**
 * Button Component
 * Based on: UXD-00 Design Foundations
 */

import { computed } from 'vue'
import { cn } from '@/lib/utils'

// Props
interface Props {
  variant?: 'primary' | 'secondary' | 'danger' | 'success' | 'ghost' | 'link'
  size?: 'sm' | 'md' | 'lg' | 'icon'
  loading?: boolean
  disabled?: boolean
  type?: 'button' | 'submit' | 'reset'
  fullWidth?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'primary',
  size: 'md',
  loading: false,
  disabled: false,
  type: 'button',
  fullWidth: false
})

// Computed classes
const buttonClasses = computed(() => {
  const baseClasses =
    'inline-flex items-center justify-center gap-2 rounded font-medium transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed'

  const variantClasses = {
    primary: 'bg-primary text-white hover:bg-primary-dark active:bg-primary-dark',
    secondary:
      'border-2 border-primary text-primary bg-transparent hover:bg-primary/10 active:bg-primary/20',
    danger: 'bg-danger text-white hover:bg-red-600 active:bg-red-700',
    success: 'bg-success text-white hover:bg-green-600 active:bg-green-700',
    ghost: 'bg-transparent text-text-primary hover:bg-surface active:bg-border',
    link: 'bg-transparent text-primary underline-offset-4 hover:underline p-0 h-auto'
  }

  const sizeClasses = {
    sm: 'h-9 px-4 text-sm',
    md: 'h-11 px-5 text-button',
    lg: 'h-12 px-7 text-button',
    icon: 'h-9 w-9 p-2'
  }

  const widthClass = props.fullWidth ? 'w-full' : ''

  return cn(baseClasses, variantClasses[props.variant], sizeClasses[props.size], widthClass)
})
</script>

<template>
  <button :type="type" :disabled="disabled || loading" :class="buttonClasses">
    <!-- Loading Spinner -->
    <svg
      v-if="loading"
      class="animate-spin h-4 w-4"
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
    >
      <circle
        class="opacity-25"
        cx="12"
        cy="12"
        r="10"
        stroke="currentColor"
        stroke-width="4"
      ></circle>
      <path
        class="opacity-75"
        fill="currentColor"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
      ></path>
    </svg>

    <!-- Slot Content -->
    <slot />
  </button>
</template>

<style scoped>
/* Force white text on colored buttons */
button.bg-primary,
button.bg-danger,
button.bg-success {
  color: white !important;
}

button.bg-primary *,
button.bg-danger *,
button.bg-success * {
  color: white !important;
}
</style>
