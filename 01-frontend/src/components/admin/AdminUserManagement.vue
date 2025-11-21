<script setup lang="ts">
/**
 * Admin User Management Component
 * Allows administrators to grant/revoke plan overrides to users
 */

import { ref } from 'vue'
import { useForm } from 'vee-validate'
import { toTypedSchema } from '@vee-validate/zod'
import { z } from 'zod'
import { grantPlanOverride, revokePlanOverride } from '@/services/user-management.service'
import { Button, Input, Label, Alert, Card, CardHeader, CardTitle, CardContent, Checkbox } from '@/components/ui'

// Validation schema
const planOverrideSchema = z.object({
  userId: z.string().uuid({ message: 'ID de usuário inválido (deve ser um GUID)' }),
  reason: z.string().min(1, 'Motivo é obrigatório').max(500, 'Motivo deve ter no máximo 500 caracteres'),
  strategyLimitOverride: z.number().int().min(1).optional().nullable(),
  featureRealtimeDataOverride: z.boolean().optional().nullable(),
  featureAdvancedAlertsOverride: z.boolean().optional().nullable(),
  featureConsultingToolsOverride: z.boolean().optional().nullable(),
  featureCommunityAccessOverride: z.boolean().optional().nullable(),
  expiresAt: z.string().optional().nullable() // ISO date string
})

// State
const isLoading = ref(false)
const isRevoking = ref(false)
const error = ref<string | null>(null)
const success = ref<string | null>(null)
const revokeUserId = ref('')

// Form setup
const { defineField, handleSubmit, errors, resetForm } = useForm({
  validationSchema: toTypedSchema(planOverrideSchema),
  initialValues: {
    userId: '',
    reason: '',
    strategyLimitOverride: null,
    featureRealtimeDataOverride: null,
    featureAdvancedAlertsOverride: null,
    featureConsultingToolsOverride: null,
    featureCommunityAccessOverride: null,
    expiresAt: null
  }
})

const [userId] = defineField('userId')
const [reason] = defineField('reason')
const [strategyLimitOverride] = defineField('strategyLimitOverride')
const [featureRealtimeDataOverride] = defineField('featureRealtimeDataOverride')
const [featureAdvancedAlertsOverride] = defineField('featureAdvancedAlertsOverride')
const [featureConsultingToolsOverride] = defineField('featureConsultingToolsOverride')
const [featureCommunityAccessOverride] = defineField('featureCommunityAccessOverride')
const [expiresAt] = defineField('expiresAt')

// Grant plan override
const onSubmit = handleSubmit(async (values) => {
  error.value = null
  success.value = null
  isLoading.value = true

  try {
    const response = await grantPlanOverride(values.userId, {
      reason: values.reason,
      strategyLimitOverride: values.strategyLimitOverride ?? undefined,
      featureRealtimeDataOverride: values.featureRealtimeDataOverride ?? undefined,
      featureAdvancedAlertsOverride: values.featureAdvancedAlertsOverride ?? undefined,
      featureConsultingToolsOverride: values.featureConsultingToolsOverride ?? undefined,
      featureCommunityAccessOverride: values.featureCommunityAccessOverride ?? undefined,
      expiresAt: values.expiresAt ?? undefined
    })

    success.value = response.message
    resetForm()
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Erro ao conceder override de plano. Tente novamente.'
  } finally {
    isLoading.value = false
  }
})

// Revoke plan override
async function handleRevoke() {
  if (!revokeUserId.value.trim()) {
    error.value = 'Por favor, insira o ID do usuário'
    return
  }

  error.value = null
  success.value = null
  isRevoking.value = true

  try {
    const response = await revokePlanOverride(revokeUserId.value)
    success.value = response.message
    revokeUserId.value = ''
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Erro ao revogar override de plano. Tente novamente.'
  } finally {
    isRevoking.value = false
  }
}
</script>

<template>
  <div class="space-y-6">
    <div>
      <h2 class="text-2xl font-bold">Gestão de Usuários</h2>
      <p class="text-gray-600 dark:text-gray-400 mt-1">
        Conceda ou revogue overrides de plano para usuários
      </p>
    </div>

    <!-- Alerts -->
    <Alert v-if="error" variant="error" dismissible @close="error = null">
      {{ error }}
    </Alert>

    <Alert v-if="success" variant="success" dismissible @close="success = null">
      {{ success }}
    </Alert>

    <!-- Grant Plan Override Form -->
    <Card>
      <CardHeader>
        <CardTitle>Conceder Override de Plano</CardTitle>
      </CardHeader>
      <CardContent>
        <form @submit="onSubmit" class="space-y-4">
          <!-- User ID -->
          <div>
            <Label for="userId">ID do Usuário (GUID) *</Label>
            <Input
              id="userId"
              v-model="userId"
              type="text"
              :error="errors.userId"
              placeholder="00000000-0000-0000-0000-000000000000"
            />
          </div>

          <!-- Reason -->
          <div>
            <Label for="reason">Motivo *</Label>
            <Input
              id="reason"
              v-model="reason"
              type="text"
              :error="errors.reason"
              placeholder="Ex: Trial de 30 dias, Beta tester, etc."
            />
          </div>

          <!-- Strategy Limit Override -->
          <div>
            <Label for="strategyLimitOverride">Limite de Estratégias (opcional)</Label>
            <Input
              id="strategyLimitOverride"
              v-model="strategyLimitOverride"
              type="number"
              step="1"
              :error="errors.strategyLimitOverride"
              placeholder="Ex: 100"
            />
            <p class="text-sm text-gray-500 mt-1">
              Deixe em branco para não sobrescrever
            </p>
          </div>

          <!-- Feature Overrides -->
          <div class="space-y-3">
            <Label>Recursos (opcional)</Label>

            <div class="flex items-center gap-2">
              <Checkbox id="featureRealtimeData" v-model:checked="featureRealtimeDataOverride" />
              <Label for="featureRealtimeData" class="cursor-pointer">Dados em Tempo Real</Label>
            </div>

            <div class="flex items-center gap-2">
              <Checkbox id="featureAdvancedAlerts" v-model:checked="featureAdvancedAlertsOverride" />
              <Label for="featureAdvancedAlerts" class="cursor-pointer">Alertas Avançados</Label>
            </div>

            <div class="flex items-center gap-2">
              <Checkbox id="featureConsultingTools" v-model:checked="featureConsultingToolsOverride" />
              <Label for="featureConsultingTools" class="cursor-pointer">Ferramentas de Consultoria</Label>
            </div>

            <div class="flex items-center gap-2">
              <Checkbox id="featureCommunityAccess" v-model:checked="featureCommunityAccessOverride" />
              <Label for="featureCommunityAccess" class="cursor-pointer">Acesso à Comunidade</Label>
            </div>
          </div>

          <!-- Expires At -->
          <div>
            <Label for="expiresAt">Data de Expiração (opcional)</Label>
            <Input
              id="expiresAt"
              v-model="expiresAt"
              type="text"
              :error="errors.expiresAt"
              placeholder="YYYY-MM-DDTHH:mm:ss"
            />
            <p class="text-sm text-gray-500 mt-1">
              Formato: 2025-12-31T23:59:59 (deixe em branco para não expirar)
            </p>
          </div>

          <!-- Submit Button -->
          <div class="flex justify-end pt-4">
            <Button type="submit" :disabled="isLoading">
              {{ isLoading ? 'Concedendo...' : 'Conceder Override' }}
            </Button>
          </div>
        </form>
      </CardContent>
    </Card>

    <!-- Revoke Plan Override -->
    <Card>
      <CardHeader>
        <CardTitle>Revogar Override de Plano</CardTitle>
      </CardHeader>
      <CardContent>
        <div class="space-y-4">
          <div>
            <Label for="revokeUserId">ID do Usuário (GUID)</Label>
            <Input
              id="revokeUserId"
              v-model="revokeUserId"
              type="text"
              placeholder="00000000-0000-0000-0000-000000000000"
            />
          </div>

          <div class="flex justify-end">
            <Button
              type="button"
              variant="danger"
              :disabled="isRevoking || !revokeUserId.trim()"
              @click="handleRevoke"
            >
              {{ isRevoking ? 'Revogando...' : 'Revogar Override' }}
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>

    <!-- Help Section -->
    <Card class="bg-blue-50 dark:bg-blue-950 border-blue-200 dark:border-blue-800">
      <CardHeader>
        <CardTitle class="text-sm text-blue-900 dark:text-blue-100">💡 Ajuda</CardTitle>
      </CardHeader>
      <CardContent class="text-sm text-blue-800 dark:text-blue-200 space-y-2">
        <p><strong>Override de Plano:</strong> Permite que você conceda recursos adicionais ou limites personalizados a usuários específicos, independentemente do plano de assinatura.</p>
        <p><strong>Como obter o ID do usuário:</strong> O ID do usuário (GUID) pode ser obtido através da API GET /api/Users/me quando o usuário está logado.</p>
        <p><strong>Recursos opcionais:</strong> Deixe desmarcados para não sobrescrever os recursos do plano atual do usuário.</p>
      </CardContent>
    </Card>
  </div>
</template>
