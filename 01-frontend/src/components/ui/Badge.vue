<script setup lang="ts">
/**
 * Badge Component
 * Based on: UXD-00 Design Foundations
 */

import { computed } from 'vue'
import { cn } from '@/lib/utils'

// Props
interface Props {
  variant?:
    | 'default'
    | 'primary'
    | 'success'
    | 'danger'
    | 'warning'
    | 'info'
    | 'active'
    | 'inactive'
    | 'suspended'
    | 'pending'
    | 'profit'
    | 'loss'
    | 'neutral'
    | 'premium'
    | 'trader'
    | 'consultant'
    | 'riskLow'
    | 'riskMedium'
    | 'riskHigh'
  size?: 'sm' | 'md'
  icon?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'default',
  size: 'md',
  icon: false
})

// Computed classes
const badgeClasses = computed(() => {
  const baseClasses = 'inline-flex items-center gap-1 font-medium rounded-full'

  const sizeClasses = {
    sm: 'px-2 py-0.5 text-xs',
    md: 'px-2.5 py-1 text-sm'
  }

  const variantClasses = {
    default: 'bg-surface text-text-primary border border-border',
    primary: 'bg-primary/10 text-primary border border-primary/20',
    success: 'bg-success/10 text-success border border-success/20',
    danger: 'bg-danger/10 text-danger border border-danger/20',
    warning: 'bg-warning/10 text-warning border border-warning/20',
    info: 'bg-info/10 text-info border border-info/20',

    // Status
    active: 'bg-success/10 text-success border border-success/20',
    inactive: 'bg-neutral/10 text-neutral border border-neutral/20',
    suspended: 'bg-danger/10 text-danger border border-danger/20',
    pending: 'bg-warning/10 text-warning border border-warning/20',

    // P&L
    profit: 'bg-profit/10 text-profit border border-profit/20 font-mono',
    loss: 'bg-loss/10 text-loss border border-loss/20 font-mono',
    neutral: 'bg-neutral/10 text-neutral border border-neutral/20 font-mono',

    // Roles
    premium: 'bg-purple-100 text-purple-700 border border-purple-200',
    trader: 'bg-blue-100 text-blue-700 border border-blue-200',
    consultant: 'bg-purple-100 text-purple-700 border border-purple-200',

    // Risk
    riskLow: 'bg-success/10 text-success border border-success/20',
    riskMedium: 'bg-warning/10 text-warning border border-warning/20',
    riskHigh: 'bg-danger/10 text-danger border border-danger/20'
  }

  return cn(baseClasses, sizeClasses[props.size], variantClasses[props.variant])
})
</script>

<template>
  <span :class="badgeClasses">
    <slot name="icon" />
    <slot />
  </span>
</template>
