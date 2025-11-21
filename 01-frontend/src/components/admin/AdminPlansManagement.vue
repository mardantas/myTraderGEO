<script setup lang="ts">
/**
 * Admin Plans Management Component
 * Allows administrators to create and update subscription plans
 */

import { ref, onMounted } from 'vue'
import { useForm } from 'vee-validate'
import { toTypedSchema } from '@vee-validate/zod'
import { z } from 'zod'
import { getPlans, configurePlan } from '@/services/plans.service'
import type { PlanResponse } from '@/types/api'
import { Button, Input, Label, Alert, Card, CardHeader, CardTitle, CardContent, Checkbox } from '@/components/ui'

// Validation schema
const planConfigSchema = z.object({
  planId: z.number().int().optional().nullable(),
  name: z.string().min(1, 'Nome é obrigatório').max(50, 'Nome deve ter no máximo 50 caracteres'),
  description: z.string().min(1, 'Descrição é obrigatória'),
  isActive: z.boolean(),
  monthlyPrice: z.number().min(0, 'Preço mensal deve ser maior ou igual a 0'),
  annualPrice: z.number().min(0, 'Preço anual deve ser maior ou igual a 0'),
  strategyLimit: z.number().int().min(0, 'Limite de estratégias deve ser maior ou igual a 0'),
  hasRealtimeData: z.boolean(),
  hasAdvancedAlerts: z.boolean(),
  hasConsultingTools: z.boolean(),
  hasCommunityAccess: z.boolean()
})

// State
const isLoading = ref(false)
const isLoadingPlans = ref(true)
const error = ref<string | null>(null)
const success = ref<string | null>(null)
const existingPlans = ref<PlanResponse[]>([])
const editingPlanId = ref<number | null>(null)

// Form setup
const { defineField, handleSubmit, errors, resetForm, setValues } = useForm({
  validationSchema: toTypedSchema(planConfigSchema),
  initialValues: {
    planId: null,
    name: '',
    description: '',
    isActive: true,
    monthlyPrice: 0,
    annualPrice: 0,
    strategyLimit: 10,
    hasRealtimeData: false,
    hasAdvancedAlerts: false,
    hasConsultingTools: false,
    hasCommunityAccess: true
  }
})

const [_planId] = defineField('planId')
const [name] = defineField('name')
const [description] = defineField('description')
const [isActive] = defineField('isActive')
const [monthlyPrice] = defineField('monthlyPrice')
const [annualPrice] = defineField('annualPrice')
const [strategyLimit] = defineField('strategyLimit')
const [hasRealtimeData] = defineField('hasRealtimeData')
const [hasAdvancedAlerts] = defineField('hasAdvancedAlerts')
const [hasConsultingTools] = defineField('hasConsultingTools')
const [hasCommunityAccess] = defineField('hasCommunityAccess')

// Load existing plans
async function loadPlans() {
  isLoadingPlans.value = true
  error.value = null

  try {
    const plans = await getPlans()
    existingPlans.value = plans
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Erro ao carregar planos'
  } finally {
    isLoadingPlans.value = false
  }
}

// Load plan for editing
function loadPlanForEdit(plan: PlanResponse) {
  editingPlanId.value = plan.id
  setValues({
    planId: plan.id,
    name: plan.name,
    description: plan.description,
    isActive: plan.isActive,
    monthlyPrice: plan.pricing.monthlyPrice,
    annualPrice: plan.pricing.annualPrice,
    strategyLimit: plan.features.strategyLimit,
    hasRealtimeData: plan.features.hasRealtimeData,
    hasAdvancedAlerts: plan.features.hasAdvancedAlerts,
    hasConsultingTools: plan.features.hasConsultingTools,
    hasCommunityAccess: plan.features.hasCommunityAccess
  })

  // Scroll to form
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

// Clear form (new plan mode)
function clearForm() {
  editingPlanId.value = null
  resetForm()
}

// Submit handler
const onSubmit = handleSubmit(async (values) => {
  error.value = null
  success.value = null
  isLoading.value = true

  try {
    const response = await configurePlan({
      planId: values.planId,
      name: values.name,
      description: values.description,
      isActive: values.isActive,
      monthlyPrice: values.monthlyPrice,
      annualPrice: values.annualPrice,
      strategyLimit: values.strategyLimit,
      hasRealtimeData: values.hasRealtimeData,
      hasAdvancedAlerts: values.hasAdvancedAlerts,
      hasConsultingTools: values.hasConsultingTools,
      hasCommunityAccess: values.hasCommunityAccess
    })

    success.value = response.message
    resetForm()
    editingPlanId.value = null

    // Reload plans
    await loadPlans()
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Erro ao configurar plano. Tente novamente.'
  } finally {
    isLoading.value = false
  }
})

// Calculate suggested annual price (15% discount)
function calculateSuggestedAnnualPrice(monthly: number | undefined): number {
  if (!monthly) return 0
  return Math.round(monthly * 12 * 0.85 * 100) / 100
}

// Load plans on mount
onMounted(() => {
  loadPlans()
})
</script>

<template>
  <div class="space-y-6">
    <div>
      <h2 class="text-2xl font-bold">Gestão de Planos</h2>
      <p class="text-gray-600 dark:text-gray-400 mt-1">
        Crie ou edite planos de assinatura
      </p>
    </div>

    <!-- Alerts -->
    <Alert v-if="error" variant="error" dismissible @close="error = null">
      {{ error }}
    </Alert>

    <Alert v-if="success" variant="success" dismissible @close="success = null">
      {{ success }}
    </Alert>

    <!-- Plan Form -->
    <Card>
      <CardHeader>
        <CardTitle>
          {{ editingPlanId ? `Editar Plano #${editingPlanId}` : 'Criar Novo Plano' }}
        </CardTitle>
      </CardHeader>
      <CardContent>
        <form @submit="onSubmit" class="space-y-4">
          <!-- Name -->
          <div>
            <Label for="name">Nome do Plano *</Label>
            <Input
              id="name"
              v-model="name"
              type="text"
              :error="errors.name"
              placeholder="Ex: Pleno, Consultor"
            />
          </div>

          <!-- Description -->
          <div>
            <Label for="description">Descrição *</Label>
            <Input
              id="description"
              v-model="description"
              type="text"
              :error="errors.description"
              placeholder="Ex: Plano ideal para traders intermediários"
            />
          </div>

          <!-- Active Status -->
          <div class="flex items-center gap-2">
            <Checkbox id="isActive" v-model:checked="isActive" />
            <Label for="isActive" class="cursor-pointer">Plano ativo (visível para usuários)</Label>
          </div>

          <!-- Pricing -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label for="monthlyPrice">Preço Mensal (R$) *</Label>
              <Input
                id="monthlyPrice"
                v-model.number="monthlyPrice"
                type="number"
                step="0.01"
                :error="errors.monthlyPrice"
                placeholder="0.00"
              />
            </div>

            <div>
              <Label for="annualPrice">Preço Anual (R$) *</Label>
              <Input
                id="annualPrice"
                v-model.number="annualPrice"
                type="number"
                step="0.01"
                :error="errors.annualPrice"
                placeholder="0.00"
              />
              <p class="text-sm text-gray-500 mt-1">
                Sugestão (15% desconto): R$ {{ calculateSuggestedAnnualPrice(monthlyPrice).toFixed(2) }}
              </p>
            </div>
          </div>

          <!-- Strategy Limit -->
          <div>
            <Label for="strategyLimit">Limite de Estratégias *</Label>
            <Input
              id="strategyLimit"
              v-model.number="strategyLimit"
              type="number"
              step="1"
              :error="errors.strategyLimit"
              placeholder="10"
            />
            <p class="text-sm text-gray-500 mt-1">
              Use 0 para ilimitado
            </p>
          </div>

          <!-- Features -->
          <div class="space-y-3">
            <Label>Recursos Incluídos</Label>

            <div class="flex items-center gap-2">
              <Checkbox id="hasRealtimeData" v-model:checked="hasRealtimeData" />
              <Label for="hasRealtimeData" class="cursor-pointer">Dados em Tempo Real</Label>
            </div>

            <div class="flex items-center gap-2">
              <Checkbox id="hasAdvancedAlerts" v-model:checked="hasAdvancedAlerts" />
              <Label for="hasAdvancedAlerts" class="cursor-pointer">Alertas Avançados</Label>
            </div>

            <div class="flex items-center gap-2">
              <Checkbox id="hasConsultingTools" v-model:checked="hasConsultingTools" />
              <Label for="hasConsultingTools" class="cursor-pointer">Ferramentas de Consultoria</Label>
            </div>

            <div class="flex items-center gap-2">
              <Checkbox id="hasCommunityAccess" v-model:checked="hasCommunityAccess" />
              <Label for="hasCommunityAccess" class="cursor-pointer">Acesso à Comunidade</Label>
            </div>
          </div>

          <!-- Actions -->
          <div class="flex justify-end gap-3 pt-4">
            <Button
              v-if="editingPlanId"
              type="button"
              variant="secondary"
              @click="clearForm"
            >
              Cancelar
            </Button>
            <Button type="submit" :disabled="isLoading">
              {{ isLoading ? 'Salvando...' : editingPlanId ? 'Atualizar Plano' : 'Criar Plano' }}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>

    <!-- Existing Plans -->
    <Card>
      <CardHeader>
        <CardTitle>Planos Existentes</CardTitle>
      </CardHeader>
      <CardContent>
        <div v-if="isLoadingPlans" class="flex justify-center py-8">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
        </div>

        <div v-else-if="existingPlans.length === 0" class="text-center py-8 text-gray-500">
          Nenhum plano encontrado
        </div>

        <div v-else class="space-y-4">
          <div
            v-for="plan in existingPlans"
            :key="plan.id"
            class="border rounded-lg p-4 hover:bg-gray-50 dark:hover:bg-gray-900 transition"
          >
            <div class="flex justify-between items-start">
              <div class="flex-1">
                <div class="flex items-center gap-2">
                  <h3 class="font-semibold text-lg">{{ plan.name }}</h3>
                  <span
                    v-if="plan.isActive"
                    class="px-2 py-1 text-xs rounded bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
                  >
                    Ativo
                  </span>
                  <span
                    v-else
                    class="px-2 py-1 text-xs rounded bg-gray-100 text-gray-800 dark:bg-gray-800 dark:text-gray-200"
                  >
                    Inativo
                  </span>
                </div>
                <p class="text-sm text-gray-600 dark:text-gray-400 mt-1">{{ plan.description }}</p>

                <div class="mt-3 grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                  <div>
                    <span class="text-gray-500">Mensal:</span>
                    <span class="font-medium ml-1">R$ {{ plan.pricing.monthlyPrice.toFixed(2) }}</span>
                  </div>
                  <div>
                    <span class="text-gray-500">Anual:</span>
                    <span class="font-medium ml-1">R$ {{ plan.pricing.annualPrice.toFixed(2) }}</span>
                  </div>
                  <div>
                    <span class="text-gray-500">Estratégias:</span>
                    <span class="font-medium ml-1">{{ plan.features.strategyLimit === 0 ? 'Ilimitado' : plan.features.strategyLimit }}</span>
                  </div>
                  <div>
                    <span class="text-gray-500">ID:</span>
                    <span class="font-medium ml-1">#{{ plan.id }}</span>
                  </div>
                </div>

                <div class="mt-2 flex flex-wrap gap-2">
                  <span
                    v-if="plan.features.hasRealtimeData"
                    class="text-xs px-2 py-1 bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200 rounded"
                  >
                    Dados em Tempo Real
                  </span>
                  <span
                    v-if="plan.features.hasAdvancedAlerts"
                    class="text-xs px-2 py-1 bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200 rounded"
                  >
                    Alertas Avançados
                  </span>
                  <span
                    v-if="plan.features.hasConsultingTools"
                    class="text-xs px-2 py-1 bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200 rounded"
                  >
                    Ferramentas de Consultoria
                  </span>
                  <span
                    v-if="plan.features.hasCommunityAccess"
                    class="text-xs px-2 py-1 bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200 rounded"
                  >
                    Acesso à Comunidade
                  </span>
                </div>
              </div>

              <Button
                type="button"
                variant="secondary"
                size="sm"
                @click="loadPlanForEdit(plan)"
              >
                Editar
              </Button>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  </div>
</template>
