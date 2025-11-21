<script setup lang="ts">
/**
 * Admin System Configuration Component
 * Allows administrators to view and update system configuration (fees and limits)
 */

import { ref, onMounted } from 'vue'
import { useForm } from 'vee-validate'
import { toTypedSchema } from '@vee-validate/zod'
import { z } from 'zod'
import { getSystemConfig, updateSystemConfig } from '@/services/system.service'
import type { SystemConfigResponse } from '@/types/api'
import { Button, Input, Label, Alert, Card, CardHeader, CardTitle, CardContent } from '@/components/ui'

// Validation schema
const systemConfigSchema = z.object({
  brokerCommissionRate: z.number().min(0).max(1).optional(),
  b3EmolumentRate: z.number().min(0).max(1).optional(),
  settlementFeeRate: z.number().min(0).max(1).optional(),
  incomeTaxRate: z.number().min(0).max(1).optional(),
  dayTradeIncomeTaxRate: z.number().min(0).max(1).optional(),
  maxOpenStrategiesPerUser: z.number().int().min(1).optional(),
  maxStrategiesInTemplate: z.number().int().min(1).optional()
})

// State
const isLoading = ref(false)
const isLoadingConfig = ref(true)
const error = ref<string | null>(null)
const success = ref<string | null>(null)
const currentConfig = ref<SystemConfigResponse | null>(null)

// Form setup
const { defineField, handleSubmit, errors, setValues } = useForm({
  validationSchema: toTypedSchema(systemConfigSchema)
})

const [brokerCommissionRate] = defineField('brokerCommissionRate')
const [b3EmolumentRate] = defineField('b3EmolumentRate')
const [settlementFeeRate] = defineField('settlementFeeRate')
const [incomeTaxRate] = defineField('incomeTaxRate')
const [dayTradeIncomeTaxRate] = defineField('dayTradeIncomeTaxRate')
const [maxOpenStrategiesPerUser] = defineField('maxOpenStrategiesPerUser')
const [maxStrategiesInTemplate] = defineField('maxStrategiesInTemplate')

// Load current configuration
async function loadConfig() {
  isLoadingConfig.value = true
  error.value = null

  try {
    const config = await getSystemConfig()
    currentConfig.value = config

    // Set form values
    setValues({
      brokerCommissionRate: config.fees.brokerCommissionRate,
      b3EmolumentRate: config.fees.b3EmolumentRate,
      settlementFeeRate: config.fees.settlementFeeRate,
      incomeTaxRate: config.fees.incomeTaxRate,
      dayTradeIncomeTaxRate: config.fees.dayTradeIncomeTaxRate,
      maxOpenStrategiesPerUser: config.maxOpenStrategiesPerUser,
      maxStrategiesInTemplate: config.maxStrategiesInTemplate
    })
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Erro ao carregar configuração do sistema'
  } finally {
    isLoadingConfig.value = false
  }
}

// Submit handler
const onSubmit = handleSubmit(async (values) => {
  error.value = null
  success.value = null
  isLoading.value = true

  try {
    await updateSystemConfig({
      brokerCommissionRate: values.brokerCommissionRate,
      b3EmolumentRate: values.b3EmolumentRate,
      settlementFeeRate: values.settlementFeeRate,
      incomeTaxRate: values.incomeTaxRate,
      dayTradeIncomeTaxRate: values.dayTradeIncomeTaxRate,
      maxOpenStrategiesPerUser: values.maxOpenStrategiesPerUser,
      maxStrategiesInTemplate: values.maxStrategiesInTemplate
    })

    success.value = 'Configuração atualizada com sucesso!'

    // Reload configuration
    await loadConfig()
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Erro ao atualizar configuração. Tente novamente.'
  } finally {
    isLoading.value = false
  }
})

// Load config on mount
onMounted(() => {
  loadConfig()
})
</script>

<template>
  <div class="space-y-6">
    <div>
      <h2 class="text-2xl font-bold">Configuração do Sistema</h2>
      <p class="text-gray-600 dark:text-gray-400 mt-1">
        Configure as taxas e limites do sistema
      </p>
    </div>

    <!-- Loading state -->
    <div v-if="isLoadingConfig" class="flex justify-center py-8">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
    </div>

    <!-- Form -->
    <form v-else @submit="onSubmit" class="space-y-6">
      <!-- Alerts -->
      <Alert v-if="error" variant="error" dismissible @close="error = null">
        {{ error }}
      </Alert>

      <Alert v-if="success" variant="success" dismissible @close="success = null">
        {{ success }}
      </Alert>

      <!-- Fees Section -->
      <Card>
        <CardHeader>
          <CardTitle>Taxas</CardTitle>
        </CardHeader>
        <CardContent class="space-y-4">
          <!-- Broker Commission Rate -->
          <div>
            <Label for="brokerCommissionRate">Taxa de Corretagem (%)</Label>
            <Input
              id="brokerCommissionRate"
              v-model.number="brokerCommissionRate"
              type="number"
              step="0.0001"
              :error="errors.brokerCommissionRate"
              placeholder="0.03"
            />
            <p class="text-sm text-gray-500 mt-1">
              Exemplo: 0.03% = 0.0003
            </p>
          </div>

          <!-- B3 Emolument Rate -->
          <div>
            <Label for="b3EmolumentRate">Taxa de Emolumentos B3 (%)</Label>
            <Input
              id="b3EmolumentRate"
              v-model.number="b3EmolumentRate"
              type="number"
              step="0.0001"
              :error="errors.b3EmolumentRate"
              placeholder="0.0325"
            />
            <p class="text-sm text-gray-500 mt-1">
              Exemplo: 0.0325% = 0.000325
            </p>
          </div>

          <!-- Settlement Fee Rate -->
          <div>
            <Label for="settlementFeeRate">Taxa de Liquidação (%)</Label>
            <Input
              id="settlementFeeRate"
              v-model.number="settlementFeeRate"
              type="number"
              step="0.0001"
              :error="errors.settlementFeeRate"
              placeholder="0.0025"
            />
            <p class="text-sm text-gray-500 mt-1">
              Exemplo: 0.0025% = 0.000025
            </p>
          </div>

          <!-- Income Tax Rate -->
          <div>
            <Label for="incomeTaxRate">Imposto de Renda - Normal (%)</Label>
            <Input
              id="incomeTaxRate"
              v-model.number="incomeTaxRate"
              type="number"
              step="0.01"
              :error="errors.incomeTaxRate"
              placeholder="15"
            />
            <p class="text-sm text-gray-500 mt-1">
              Exemplo: 15% = 0.15
            </p>
          </div>

          <!-- Day Trade Income Tax Rate -->
          <div>
            <Label for="dayTradeIncomeTaxRate">Imposto de Renda - Day Trade (%)</Label>
            <Input
              id="dayTradeIncomeTaxRate"
              v-model.number="dayTradeIncomeTaxRate"
              type="number"
              step="0.01"
              :error="errors.dayTradeIncomeTaxRate"
              placeholder="20"
            />
            <p class="text-sm text-gray-500 mt-1">
              Exemplo: 20% = 0.20
            </p>
          </div>
        </CardContent>
      </Card>

      <!-- Limits Section -->
      <Card>
        <CardHeader>
          <CardTitle>Limites do Sistema</CardTitle>
        </CardHeader>
        <CardContent class="space-y-4">
          <!-- Max Open Strategies Per User -->
          <div>
            <Label for="maxOpenStrategiesPerUser">Máximo de Estratégias Abertas por Usuário</Label>
            <Input
              id="maxOpenStrategiesPerUser"
              v-model.number="maxOpenStrategiesPerUser"
              type="number"
              step="1"
              :error="errors.maxOpenStrategiesPerUser"
              placeholder="10"
            />
          </div>

          <!-- Max Strategies In Template -->
          <div>
            <Label for="maxStrategiesInTemplate">Máximo de Estratégias em Template</Label>
            <Input
              id="maxStrategiesInTemplate"
              v-model.number="maxStrategiesInTemplate"
              type="number"
              step="1"
              :error="errors.maxStrategiesInTemplate"
              placeholder="5"
            />
          </div>
        </CardContent>
      </Card>

      <!-- Actions -->
      <div class="flex justify-end gap-3">
        <Button type="button" variant="secondary" @click="loadConfig">
          Resetar
        </Button>
        <Button type="submit" :disabled="isLoading">
          {{ isLoading ? 'Salvando...' : 'Salvar Configuração' }}
        </Button>
      </div>
    </form>

    <!-- Current Config Info -->
    <Card v-if="currentConfig" class="bg-gray-50 dark:bg-gray-900">
      <CardHeader>
        <CardTitle class="text-sm">Informações da Configuração</CardTitle>
      </CardHeader>
      <CardContent class="text-sm space-y-1">
        <p><strong>Última atualização:</strong> {{ new Date(currentConfig.updatedAt).toLocaleString('pt-BR') }}</p>
        <p><strong>Atualizado por:</strong> {{ currentConfig.updatedBy }}</p>
      </CardContent>
    </Card>
  </div>
</template>
