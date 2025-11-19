<script setup lang="ts">
/**
 * Label Component
 * Based on: UXD-00 Design Foundations
 */

// Props
interface Props {
  for?: string
  required?: boolean
}

const _props = withDefaults(defineProps<Props>(), {
  required: false,
})
</script>

<template>
  <label
    :for="for"
    class="block text-sm font-medium text-text-primary mb-1"
  >
    <slot />
    <span v-if="required" class="text-danger ml-1" aria-label="required">*</span>
  </label>
</template>
