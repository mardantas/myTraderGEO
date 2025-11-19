<script setup lang="ts">
/**
 * Card Component
 * Based on: UXD-00 Design Foundations
 */

import { cn } from '@/lib/utils'

// Props
interface Props {
  hoverable?: boolean
  noPadding?: boolean
}

// @ts-expect-error - Props used in template, not in script
const _props = withDefaults(defineProps<Props>(), {
  hoverable: false,
  noPadding: false,
})
</script>

<template>
  <div
    :class="cn(
      'bg-white border border-border rounded-lg shadow-md transition-shadow',
      hoverable && 'hover:shadow-lg cursor-pointer',
      !noPadding && 'p-6'
    )"
  >
    <slot />
  </div>
</template>
