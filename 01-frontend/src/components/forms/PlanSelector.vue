<script setup lang="ts">
/**
 * Plan Selector Component
 * Based on: UXD-01 > WF-01: Sign Up - Plan Selection
 */

import { computed } from 'vue'
import { BillingPeriod, type Plan } from '@/types'
import { formatCurrency } from '@/lib/utils'
import { Badge } from '@/components/ui'
import { CheckIcon } from '@heroicons/vue/24/solid'

// Props
interface Props {
  modelValuePlan?: number
  modelValueBilling?: BillingPeriod
}

const props = withDefaults(defineProps<Props>(), {
  modelValuePlan: 2, // Pleno (default)
  modelValueBilling: BillingPeriod.Monthly,
})

// Emits
const emit = defineEmits<{
  'update:modelValuePlan': [value: number]
  'update:modelValueBilling': [value: BillingPeriod]
}>()

// Plans data
const plans: Plan[] = [
  {
    id: 1,
    name: 'Básico',
    price: 0,
    billingPeriod: BillingPeriod.Monthly,
    monthlyPrice: 0,
    annualPrice: 0,
    strategyLimit: 1,
    hasRealtimeData: false,
    hasAdvancedAlerts: false,
    hasConsultingTools: false,
    hasCommunityAccess: true,
    isActive: true,
    features: {
      realtimeData: false,
      advancedAlerts: false,
      consultingTools: false,
      communityAccess: true,
    },
  },
  {
    id: 2,
    name: 'Pleno',
    price: 49.9,
    billingPeriod: BillingPeriod.Monthly,
    monthlyPrice: 49.9,
    annualPrice: 479.04, // 20% discount
    strategyLimit: null, // unlimited
    hasRealtimeData: true,
    hasAdvancedAlerts: true,
    hasConsultingTools: false,
    hasCommunityAccess: true,
    isActive: true,
    recommended: true,
    features: {
      realtimeData: true,
      advancedAlerts: true,
      consultingTools: false,
      communityAccess: true,
    },
  },
  {
    id: 3,
    name: 'Consultor',
    price: 99.9,
    billingPeriod: BillingPeriod.Monthly,
    monthlyPrice: 99.9,
    annualPrice: 959.04, // 20% discount
    strategyLimit: null, // unlimited
    hasRealtimeData: true,
    hasAdvancedAlerts: true,
    hasConsultingTools: true,
    hasCommunityAccess: true,
    isActive: true,
    features: {
      realtimeData: true,
      advancedAlerts: true,
      consultingTools: true,
      communityAccess: true,
    },
  },
]

// Local state
const selectedPlanId = computed({
  get: () => props.modelValuePlan,
  set: (value) => emit('update:modelValuePlan', value),
})

const billingPeriod = computed({
  get: () => props.modelValueBilling,
  set: (value) => emit('update:modelValueBilling', value),
})

// Computed
const isAnnual = computed(() => billingPeriod.value === BillingPeriod.Annual)

function getPlanPrice(plan: Plan): number {
  return isAnnual.value ? plan.annualPrice : plan.monthlyPrice
}

function getMonthlyEquivalent(plan: Plan): string {
  if (isAnnual.value && plan.annualPrice > 0) {
    const monthly = plan.annualPrice / 12
    return formatCurrency(monthly) + '/mês'
  }
  return ''
}

function selectPlan(planId: number) {
  selectedPlanId.value = planId
}

function toggleBillingPeriod() {
  billingPeriod.value = isAnnual.value ? BillingPeriod.Monthly : BillingPeriod.Annual
}
</script>

<template>
  <div class="space-y-4">
    <!-- Billing Period Toggle -->
    <div class="flex items-center justify-center gap-3 mb-6">
      <span
        :class="!isAnnual ? 'text-text-primary font-medium' : 'text-text-secondary'"
      >
        Mensal
      </span>
      <button
        type="button"
        :class="[
          'relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-primary focus:ring-offset-2',
          isAnnual ? 'bg-primary' : 'bg-border',
        ]"
        @click="toggleBillingPeriod"
      >
        <span
          :class="[
            'inline-block h-4 w-4 transform rounded-full bg-white transition-transform',
            isAnnual ? 'translate-x-6' : 'translate-x-1',
          ]"
        />
      </button>
      <span
        :class="isAnnual ? 'text-text-primary font-medium' : 'text-text-secondary'"
      >
        Anual
        <Badge variant="success" size="sm" class="ml-1">-20%</Badge>
      </span>
    </div>

    <!-- Plans Grid -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div
        v-for="plan in plans"
        :key="plan.id"
        :class="[
          'relative border-2 rounded-lg p-5 cursor-pointer transition-all',
          selectedPlanId === plan.id
            ? 'border-primary bg-primary/5'
            : 'border-border hover:border-primary/50',
        ]"
        @click="selectPlan(plan.id)"
      >
        <!-- Recommended Badge -->
        <div v-if="plan.recommended" class="absolute -top-3 left-1/2 -translate-x-1/2">
          <Badge variant="premium">Recomendado</Badge>
        </div>

        <!-- Selected Checkmark -->
        <div
          v-if="selectedPlanId === plan.id"
          class="absolute top-3 right-3 w-6 h-6 bg-primary rounded-full flex items-center justify-center"
        >
          <CheckIcon class="w-4 h-4 text-white" />
        </div>

        <!-- Plan Name -->
        <h4 class="text-h4 font-semibold text-text-primary mb-1">{{ plan.name }}</h4>

        <!-- Price -->
        <div class="mb-4">
          <div class="text-h2 font-bold text-text-primary">
            {{ formatCurrency(getPlanPrice(plan)) }}
          </div>
          <div class="text-xs text-text-secondary">
            {{ isAnnual ? '/ano' : '/mês' }}
            <span v-if="getMonthlyEquivalent(plan)" class="block">
              ({{ getMonthlyEquivalent(plan) }})
            </span>
          </div>
        </div>

        <!-- Features -->
        <ul class="space-y-2 text-sm">
          <li class="flex items-center gap-2">
            <CheckIcon class="w-4 h-4 text-success flex-shrink-0" />
            <span>
              {{ plan.strategyLimit === null ? 'Estratégias ilimitadas' : `${plan.strategyLimit} estratégia` }}
            </span>
          </li>
          <li :class="plan.features.realtimeData ? 'text-text-primary' : 'text-text-tertiary'">
            <CheckIcon
              v-if="plan.features.realtimeData"
              class="w-4 h-4 text-success inline mr-2"
            />
            <span v-else class="inline-block w-4 h-4 mr-2">×</span>
            Dados em tempo real
          </li>
          <li :class="plan.features.advancedAlerts ? 'text-text-primary' : 'text-text-tertiary'">
            <CheckIcon
              v-if="plan.features.advancedAlerts"
              class="w-4 h-4 text-success inline mr-2"
            />
            <span v-else class="inline-block w-4 h-4 mr-2">×</span>
            Alertas avançados
          </li>
          <li :class="plan.features.consultingTools ? 'text-text-primary' : 'text-text-tertiary'">
            <CheckIcon
              v-if="plan.features.consultingTools"
              class="w-4 h-4 text-success inline mr-2"
            />
            <span v-else class="inline-block w-4 h-4 mr-2">×</span>
            Ferramentas de consultoria
          </li>
          <li :class="plan.features.communityAccess ? 'text-text-primary' : 'text-text-tertiary'">
            <CheckIcon
              v-if="plan.features.communityAccess"
              class="w-4 h-4 text-success inline mr-2"
            />
            <span v-else class="inline-block w-4 h-4 mr-2">×</span>
            Acesso à comunidade
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>
