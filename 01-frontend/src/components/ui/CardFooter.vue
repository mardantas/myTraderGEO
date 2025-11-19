<script setup lang="ts">
/**
 * Card Footer Component
 */

import { cn } from '@/lib/utils'

// Props
interface Props {
  noBorder?: boolean
}

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const _props = withDefaults(defineProps<Props>(), {
  noBorder: false,
})
</script>

<template>
  <div
    :class="cn(
      'px-6 py-4',
      !noBorder && 'border-t border-border'
    )"
  >
    <slot />
  </div>
</template>
