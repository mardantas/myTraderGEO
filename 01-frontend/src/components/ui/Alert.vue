<script setup lang="ts">
/**
 * Alert Component
 * Based on: UXD-00 Design Foundations
 */

import { computed } from 'vue'
import { cn } from '@/lib/utils'
import {
  InformationCircleIcon,
  CheckCircleIcon,
  ExclamationTriangleIcon,
  XCircleIcon,
  XMarkIcon,
} from '@heroicons/vue/24/outline'

// Props
interface Props {
  variant?: 'info' | 'success' | 'warning' | 'error'
  dismissible?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'info',
  dismissible: false,
})

// Emits
const emit = defineEmits<{
  close: []
}>()

// Computed
const alertClasses = computed(() => {
  const baseClasses = 'relative p-4 rounded-lg border'

  const variantClasses = {
    info: 'bg-info/10 border-info/20 text-info',
    success: 'bg-success/10 border-success/20 text-success',
    warning: 'bg-warning/10 border-warning/20 text-warning',
    error: 'bg-danger/10 border-danger/20 text-danger',
  }

  return cn(baseClasses, variantClasses[props.variant])
})

const icon = computed(() => {
  const icons = {
    info: InformationCircleIcon,
    success: CheckCircleIcon,
    warning: ExclamationTriangleIcon,
    error: XCircleIcon,
  }
  return icons[props.variant]
})

// Methods
function handleClose() {
  emit('close')
}
</script>

<template>
  <div :class="alertClasses">
    <div class="flex gap-3">
      <!-- Icon -->
      <component :is="icon" class="w-5 h-5 flex-shrink-0 mt-0.5" />

      <!-- Content -->
      <div class="flex-1 text-sm text-text-primary">
        <slot />
      </div>

      <!-- Close Button -->
      <button
        v-if="dismissible"
        type="button"
        class="flex-shrink-0 text-text-secondary hover:text-text-primary transition-colors"
        @click="handleClose"
      >
        <XMarkIcon class="w-5 h-5" />
      </button>
    </div>
  </div>
</template>
