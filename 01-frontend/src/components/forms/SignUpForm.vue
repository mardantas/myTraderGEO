<script setup lang="ts">
/**
 * Sign Up Form Component
 * Based on: UXD-01 > WF-01: Sign Up
 */

import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useForm } from 'vee-validate'
import { toTypedSchema } from '@vee-validate/zod'
import { signUpSchema, calculatePasswordStrength } from '@/lib/validations'
import { useAuthStore } from '@/stores'
import { RiskProfile, BillingPeriod, RISK_PROFILE_LABELS } from '@/types'
import { Button, Input, Label, Checkbox, Alert } from '@/components/ui'
import PlanSelector from './PlanSelector.vue'

// Router & Store
const router = useRouter()
const authStore = useAuthStore()

// Form setup
const { defineField, handleSubmit, errors, values } = useForm({
  validationSchema: toTypedSchema(signUpSchema),
  initialValues: {
    fullName: '',
    displayName: '',
    email: '',
    password: '',
    confirmPassword: '',
    countryCode: '',
    phoneNumber: '',
    riskProfile: RiskProfile.Moderate,
    subscriptionPlanId: 2, // Pleno (default)
    billingPeriod: BillingPeriod.Monthly,
    termsAccepted: false
  }
})

const [fullName] = defineField('fullName')
const [displayName] = defineField('displayName')
const [email] = defineField('email')
const [password] = defineField('password')
const [confirmPassword] = defineField('confirmPassword')
const [countryCode] = defineField('countryCode')
const [phoneNumber] = defineField('phoneNumber')
const [riskProfile] = defineField('riskProfile')
const [subscriptionPlanId] = defineField('subscriptionPlanId')
const [billingPeriod] = defineField('billingPeriod')
const [termsAccepted] = defineField('termsAccepted')

// State
const isLoading = ref(false)
const error = ref<string | null>(null)

// Common countries for phone selection
const countries = [
  { code: '', name: '(Nenhum)', flag: '' },
  { code: '+55', name: 'Brasil', flag: '🇧🇷' },
  { code: '+1', name: 'Estados Unidos / Canadá', flag: '🇺🇸' },
  { code: '+351', name: 'Portugal', flag: '🇵🇹' },
  { code: '+54', name: 'Argentina', flag: '🇦🇷' },
  { code: '+52', name: 'México', flag: '🇲🇽' },
  { code: '+34', name: 'Espanha', flag: '🇪🇸' },
  { code: '+44', name: 'Reino Unido', flag: '🇬🇧' },
  { code: '+49', name: 'Alemanha', flag: '🇩🇪' },
  { code: '+33', name: 'França', flag: '🇫🇷' },
  { code: '+39', name: 'Itália', flag: '🇮🇹' }
]

// Password strength
const passwordStrength = computed(() => {
  return calculatePasswordStrength(values.password || '')
})

// Submit handler
const onSubmit = handleSubmit(async (formValues) => {
  error.value = null
  isLoading.value = true

  try {
    // Parse phone number (optional)
    await authStore.signUp({
      fullName: formValues.fullName,
      displayName: formValues.displayName,
      email: formValues.email,
      password: formValues.password,
      riskProfile: formValues.riskProfile,
      subscriptionPlanId: formValues.subscriptionPlanId,
      billingPeriod: formValues.billingPeriod
    })

    // Redirect to dashboard with welcome message
    router.push({ name: 'Dashboard', query: { welcome: 'true' } })
  } catch (err: any) {
    // Log full error details to console
    console.error('Registration error details:', {
      err,
      problemDetails: err?.problemDetails,
      errors: err?.problemDetails?.errors,
      message: err?.message,
      status: err?.status
    })

    // Show detailed validation errors if available
    if (err?.problemDetails?.errors) {
      const validationErrors = Object.entries(err.problemDetails.errors)
        .map(([field, messages]) => `${field}: ${(messages as string[]).join(', ')}`)
        .join('\n')
      error.value = `Erros de validação:\n${validationErrors}`
    } else {
      error.value = err instanceof Error ? err.message : 'Erro ao criar conta. Tente novamente.'
    }
  } finally {
    isLoading.value = false
  }
})
</script>

<template>
  <form @submit="onSubmit" class="space-y-6">
    <!-- Error Alert -->
    <Alert v-if="error" variant="error" dismissible @close="error = null">
      {{ error }}
    </Alert>

    <!-- Personal Information -->
    <div class="space-y-4">
      <h3 class="text-h4 font-semibold text-text-primary">Informações Pessoais</h3>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <!-- Full Name -->
        <div>
          <Label for="fullName" required>Nome Completo</Label>
          <Input
            id="fullName"
            v-model="fullName"
            type="text"
            placeholder="João da Silva"
            :error="errors.fullName"
            :disabled="isLoading"
          />
        </div>

        <!-- Display Name -->
        <div>
          <Label for="displayName" required>Nome de Exibição</Label>
          <Input
            id="displayName"
            v-model="displayName"
            type="text"
            placeholder="João"
            helper-text="Nome exibido na comunidade"
            :error="errors.displayName"
            :disabled="isLoading"
          />
        </div>
      </div>

      <!-- Email -->
      <div>
        <Label for="email" required>Email</Label>
        <Input
          id="email"
          v-model="email"
          type="email"
          placeholder="seu@email.com"
          :error="errors.email"
          :disabled="isLoading"
        />
      </div>

      <!-- Phone (Optional) -->
      <div>
        <Label for="countryCode">Telefone (Opcional)</Label>
        <div class="grid grid-cols-5 gap-2">
          <div class="col-span-2">
            <select
              id="countryCode"
              v-model="countryCode"
              class="w-full px-3 py-2.5 border border-border rounded text-sm focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none disabled:bg-surface disabled:cursor-not-allowed"
              :disabled="isLoading"
            >
              <option v-for="country in countries" :key="country.code" :value="country.code">
                {{ country.flag }} {{ country.name }}
              </option>
            </select>
            <p v-if="errors.countryCode" class="mt-1 text-xs text-danger">
              {{ errors.countryCode }}
            </p>
          </div>
          <div class="col-span-3">
            <Input
              id="phoneNumber"
              v-model="phoneNumber"
              type="tel"
              placeholder="11987654321"
              helper-text="Somente números (ex: 11987654321)"
              :error="errors.phoneNumber"
              :disabled="isLoading || !countryCode"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Password -->
    <div class="space-y-4">
      <h3 class="text-h4 font-semibold text-text-primary">Senha</h3>

      <!-- Password -->
      <div>
        <Label for="password" required>Senha</Label>
        <Input
          id="password"
          v-model="password"
          type="password"
          placeholder="••••••••"
          helper-text="Mínimo 8 caracteres, 1 maiúscula, 1 minúscula, 1 número"
          :error="errors.password"
          :disabled="isLoading"
        />

        <!-- Password Strength Indicator -->
        <div v-if="password" class="mt-2">
          <div class="flex items-center gap-2 mb-1">
            <div class="flex-1 h-2 bg-surface rounded-full overflow-hidden">
              <div
                :class="[
                  'h-full transition-all',
                  passwordStrength.score === 0 && 'w-0',
                  passwordStrength.score === 1 && 'w-1/4 bg-danger',
                  passwordStrength.score === 2 && 'w-2/4 bg-warning',
                  passwordStrength.score === 3 && 'w-3/4 bg-info',
                  passwordStrength.score === 4 && 'w-full bg-success'
                ]"
              />
            </div>
            <span
              :class="[
                'text-xs font-medium',
                passwordStrength.color === 'danger' && 'text-danger',
                passwordStrength.color === 'warning' && 'text-warning',
                passwordStrength.color === 'info' && 'text-info',
                passwordStrength.color === 'success' && 'text-success'
              ]"
            >
              {{ passwordStrength.label }}
            </span>
          </div>
        </div>
      </div>

      <!-- Confirm Password -->
      <div>
        <Label for="confirmPassword" required>Confirmar Senha</Label>
        <Input
          id="confirmPassword"
          v-model="confirmPassword"
          type="password"
          placeholder="••••••••"
          :error="errors.confirmPassword"
          :disabled="isLoading"
        />
      </div>
    </div>

    <!-- Risk Profile -->
    <div>
      <Label for="riskProfile" required>Perfil de Risco</Label>
      <select
        id="riskProfile"
        v-model="riskProfile"
        class="w-full px-3 py-2.5 border border-border rounded text-sm focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none"
        :disabled="isLoading"
      >
        <option v-for="(data, key) in RISK_PROFILE_LABELS" :key="key" :value="key">
          {{ data.label }} - {{ data.description }}
        </option>
      </select>
      <p class="mt-1 text-xs text-text-secondary">
        ℹ️ Este perfil influencia recomendações e alertas de risco.
      </p>
      <p v-if="errors.riskProfile" class="mt-1 text-xs text-danger">
        {{ errors.riskProfile }}
      </p>
    </div>

    <!-- Subscription Plan -->
    <div>
      <h3 class="text-h4 font-semibold text-text-primary mb-4">Escolha seu Plano</h3>
      <PlanSelector
        v-model:model-value-plan="subscriptionPlanId"
        v-model:model-value-billing="billingPeriod"
      />
      <p v-if="errors.subscriptionPlanId" class="mt-2 text-xs text-danger">
        {{ errors.subscriptionPlanId }}
      </p>
    </div>

    <!-- Terms & Conditions -->
    <div>
      <Checkbox
        id="termsAccepted"
        v-model="termsAccepted"
        :error="errors.termsAccepted"
        :disabled="isLoading"
      >
        Eu li e aceito os
        <a href="#" class="text-primary hover:text-primary-dark">Termos & Condições</a>
        e a
        <a href="#" class="text-primary hover:text-primary-dark">Política de Privacidade</a>
      </Checkbox>
    </div>

    <!-- Submit Button -->
    <Button type="submit" :loading="isLoading" full-width>
      {{ isLoading ? 'Criando conta...' : 'Criar Conta' }}
    </Button>

    <!-- Login Link -->
    <p class="text-center text-sm text-text-secondary mt-4">
      Já tem uma conta?
      <router-link
        to="/login"
        class="text-primary font-medium hover:text-primary-dark transition-colors"
      >
        Fazer login
      </router-link>
    </p>
  </form>
</template>
