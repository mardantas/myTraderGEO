<script setup lang="ts">
/**
 * View Profile Page
 * Based on: UXD-01 > WF-03: View Profile
 */

import { computed } from 'vue'
import { useAuthStore } from '@/stores'
import { formatPhoneNumber } from '@/lib/utils'
import { RISK_PROFILE_LABELS, USER_STATUS_LABELS } from '@/types'
import {
  Card,
  CardHeader,
  CardTitle,
  CardContent,
  Button,
  Badge,
  Alert,
} from '@/components/ui'
import { CheckIcon, XMarkIcon, PencilIcon } from '@heroicons/vue/24/outline'

// Store
const authStore = useAuthStore()

// Computed
const user = computed(() => authStore.currentUser)

const formattedPhone = computed(() => {
  if (!user.value?.phoneNumber) return null
  return formatPhoneNumber(
    user.value.phoneNumber.countryCode,
    user.value.phoneNumber.number
  )
})

const nextBillingDate = computed(() => {
  // Mock - should come from user data
  return '14/12/2025'
})
</script>

<template>
  <div v-if="user" class="max-w-4xl mx-auto space-y-6">
    <!-- Page Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-h1">Meu Perfil</h1>
        <nav class="text-sm text-text-secondary mt-1">
          Dashboard &gt; Perfil
        </nav>
      </div>
    </div>

    <!-- 1. Personal Information Card -->
    <Card>
      <CardHeader>
        <div class="flex items-center justify-between">
          <CardTitle>Informações Pessoais</CardTitle>
          <Button variant="ghost" size="icon" as="router-link" to="/dashboard/profile/edit">
            <router-link to="/dashboard/profile/edit">
              <PencilIcon class="w-5 h-5" />
            </router-link>
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <!-- Full Name -->
          <div>
            <div class="text-sm text-text-secondary">Nome Completo</div>
            <div class="text-base font-medium text-text-primary mt-1">
              {{ user.fullName }}
            </div>
          </div>

          <!-- Display Name -->
          <div>
            <div class="text-sm text-text-secondary">Nome de Exibição</div>
            <div class="text-base font-medium text-text-primary mt-1">
              {{ user.displayName }}
            </div>
          </div>

          <!-- Email -->
          <div>
            <div class="text-sm text-text-secondary">Email</div>
            <div class="text-base font-medium text-text-primary mt-1">
              {{ user.email.value }}
            </div>
          </div>

          <!-- Phone -->
          <div>
            <div class="text-sm text-text-secondary">Telefone</div>
            <div class="flex items-center gap-2 mt-1">
              <template v-if="formattedPhone">
                <span class="text-base font-medium text-text-primary">
                  {{ formattedPhone }}
                </span>
                <Badge v-if="user.isPhoneVerified" variant="active" size="sm">
                  <template #icon>
                    <CheckIcon class="w-3 h-3" />
                  </template>
                  Verificado
                </Badge>
                <Button variant="link" size="sm" as="router-link" to="/dashboard/profile/phone/change">
                  Alterar
                </Button>
              </template>
              <template v-else>
                <span class="text-base text-text-secondary">Não cadastrado</span>
                <Button variant="link" size="sm" as="router-link" to="/dashboard/profile/phone/add">
                  Adicionar
                </Button>
              </template>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>

    <!-- 2. Trading Profile Card -->
    <Card>
      <CardHeader>
        <CardTitle>Perfil de Trading</CardTitle>
      </CardHeader>
      <CardContent>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <!-- Role -->
          <div>
            <div class="text-sm text-text-secondary">Função</div>
            <div class="mt-1">
              <Badge variant="trader">{{ user.role }}</Badge>
            </div>
          </div>

          <!-- Risk Profile -->
          <div>
            <div class="text-sm text-text-secondary">Perfil de Risco</div>
            <div class="mt-1">
              <Badge variant="riskMedium">
                {{ RISK_PROFILE_LABELS[user.riskProfile].label }}
              </Badge>
            </div>
          </div>

          <!-- Subscription Plan -->
          <div>
            <div class="text-sm text-text-secondary">Plano de Assinatura</div>
            <div class="flex items-center gap-2 mt-1">
              <Badge variant="premium">{{ user.subscriptionPlan?.name || 'Básico' }}</Badge>
              <span class="text-sm text-text-secondary">
                ({{ user.billingPeriod === 'Monthly' ? 'Mensal' : 'Anual' }})
              </span>
            </div>
          </div>

          <!-- Status -->
          <div>
            <div class="text-sm text-text-secondary">Status</div>
            <div class="mt-1">
              <Badge :variant="USER_STATUS_LABELS[user.status].color as any">
                {{ USER_STATUS_LABELS[user.status].label }}
              </Badge>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>

    <!-- 3. Plan Details Card -->
    <Card>
      <CardHeader>
        <div class="flex items-center justify-between">
          <CardTitle>Detalhes do Plano</CardTitle>
          <Button variant="secondary" size="sm" as="router-link" to="/dashboard/profile/upgrade">
            Upgrade de Plano
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        <div class="space-y-4">
          <!-- Strategy Limit -->
          <div>
            <div class="text-sm text-text-secondary">Limite de Estratégias</div>
            <div class="text-base font-medium text-text-primary mt-1">
              {{
                user.subscriptionPlan?.strategyLimit === null
                  ? 'Ilimitado'
                  : user.subscriptionPlan?.strategyLimit
              }}
            </div>
          </div>

          <!-- Features -->
          <div>
            <div class="text-sm text-text-secondary mb-2">Recursos Incluídos</div>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-2">
              <div class="flex items-center gap-2">
                <CheckIcon
                  v-if="user.subscriptionPlan?.hasRealtimeData"
                  class="w-5 h-5 text-success"
                />
                <XMarkIcon v-else class="w-5 h-5 text-danger" />
                <span class="text-sm">Dados em Tempo Real</span>
              </div>

              <div class="flex items-center gap-2">
                <CheckIcon
                  v-if="user.subscriptionPlan?.hasAdvancedAlerts"
                  class="w-5 h-5 text-success"
                />
                <XMarkIcon v-else class="w-5 h-5 text-danger" />
                <span class="text-sm">Alertas Avançados</span>
              </div>

              <div class="flex items-center gap-2">
                <CheckIcon
                  v-if="user.subscriptionPlan?.hasConsultingTools"
                  class="w-5 h-5 text-success"
                />
                <XMarkIcon v-else class="w-5 h-5 text-danger" />
                <span class="text-sm">Ferramentas de Consultoria</span>
              </div>

              <div class="flex items-center gap-2">
                <CheckIcon
                  v-if="user.subscriptionPlan?.hasCommunityAccess"
                  class="w-5 h-5 text-success"
                />
                <XMarkIcon v-else class="w-5 h-5 text-danger" />
                <span class="text-sm">Acesso à Comunidade</span>
              </div>
            </div>
          </div>

          <!-- Next Billing -->
          <div>
            <div class="text-sm text-text-secondary">Próxima Cobrança</div>
            <div class="text-base font-medium text-text-primary mt-1">
              {{ nextBillingDate }} - R$
              {{
                user.subscriptionPlan?.price.toFixed(2).replace('.', ',') || '0,00'
              }}
            </div>
          </div>
        </div>
      </CardContent>
    </Card>

    <!-- 4. Plan Override Alert (conditional) -->
    <Alert v-if="user.planOverride" variant="warning">
      <strong>⚠️ Acesso Especial Ativo</strong>
      <div class="mt-2 space-y-1">
        <p class="text-sm">
          <strong>Motivo:</strong> {{ user.planOverride.reason }}
        </p>
        <p class="text-sm">
          <strong>Expira em:</strong>
          {{
            user.planOverride.expiresAt
              ? new Date(user.planOverride.expiresAt).toLocaleDateString('pt-BR')
              : 'Permanente'
          }}
        </p>
        <div v-if="user.planOverride.overriddenFeatures.length > 0" class="text-sm">
          <strong>Benefícios Temporários:</strong>
          <ul class="list-disc list-inside mt-1">
            <li v-for="(feature, idx) in user.planOverride.overriddenFeatures" :key="idx">
              {{ feature }}
            </li>
          </ul>
        </div>
      </div>
    </Alert>
  </div>
</template>
