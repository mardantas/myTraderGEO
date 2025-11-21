<script setup lang="ts">
/**
 * Card Header Component
 */

import { cn } from '@/lib/utils'

// Props
interface Props {
  noBorder?: boolean
}

withDefaults(defineProps<Props>(), {
  noBorder: false
})
</script>

<template>
  <div :class="cn('px-6 py-4', !noBorder && 'border-b border-border')">
    <slot />
  </div>
</template>
