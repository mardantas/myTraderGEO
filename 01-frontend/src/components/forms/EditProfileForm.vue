<script setup lang="ts">
/**
 * Edit Profile Form Component
 * Based on: UXD-01 > WF-04: Edit Profile
 */

import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useForm } from 'vee-validate'
import { toTypedSchema } from '@vee-validate/zod'
import { editProfileSchema } from '@/lib/validations'
import { useAuthStore } from '@/stores'
import { RISK_PROFILE_LABELS, RiskProfile } from '@/types'
import { Button, Input, Label, Alert } from '@/components/ui'

// Props
interface Props {
  onSuccess?: () => void
}

const props = defineProps<Props>()

// Router & Store
const router = useRouter()
const authStore = useAuthStore()

// Current user
const currentUser = authStore.currentUser

// Form setup
const { defineField, handleSubmit, errors } = useForm({
  validationSchema: toTypedSchema(editProfileSchema),
  initialValues: {
    displayName: currentUser?.displayName || '',
    riskProfile: currentUser?.riskProfile || RiskProfile.Moderate,
  },
})

const [displayName] = defineField('displayName')
const [riskProfile] = defineField('riskProfile')

// State
const isLoading = ref(false)
const error = ref<string | null>(null)

// Submit handler
const onSubmit = handleSubmit(async (values) => {
  error.value = null
  isLoading.value = true

  try {
    // TODO: Replace with actual API call
    const response = await fetch(`${import.meta.env.VITE_API_URL}/users/me`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${authStore.token}`,
      },
      body: JSON.stringify({
        displayName: values.displayName,
        riskProfile: values.riskProfile,
      }),
    })

    if (!response.ok) {
      const errorData = await response.json()
      throw new Error(errorData.message || 'Erro ao atualizar perfil')
    }

    const updatedUser = await response.json()

    // Update user in store
    authStore.updateUser(updatedUser.user || updatedUser)

    // Call success callback or navigate
    if (props.onSuccess) {
      props.onSuccess()
    } else {
      router.push('/dashboard/profile')
    }
  } catch (err) {
    error.value =
      err instanceof Error ? err.message : 'Erro ao atualizar perfil. Tente novamente.'
  } finally {
    isLoading.value = false
  }
})

function handleCancel() {
  router.push('/dashboard/profile')
}
</script>

<template>
  <form @submit="onSubmit" class="space-y-5">
    <!-- Error Alert -->
    <Alert v-if="error" variant="error" dismissible @close="error = null">
      {{ error }}
    </Alert>

    <!-- Full Name (Read-only) -->
    <div>
      <Label for="fullName">Nome Completo</Label>
      <Input
        id="fullName"
        type="text"
        :model-value="currentUser?.fullName"
        disabled
        helper-text="Não é possível alterar o nome completo."
      />
    </div>

    <!-- Display Name (Editable) -->
    <div>
      <Label for="displayName" required>Nome de Exibição</Label>
      <Input
        id="displayName"
        v-model="displayName"
        type="text"
        placeholder="João"
        helper-text="Este nome será exibido na comunidade."
        :error="errors.displayName"
        :disabled="isLoading"
      />
    </div>

    <!-- Email (Read-only) -->
    <div>
      <Label for="email">Email</Label>
      <Input
        id="email"
        type="email"
        :model-value="currentUser?.email.value"
        disabled
        helper-text="Para alterar o email, entre em contato com o suporte."
      />
    </div>

    <!-- Risk Profile (Editable) -->
    <div>
      <Label for="riskProfile" required>Perfil de Risco</Label>
      <select
        id="riskProfile"
        v-model="riskProfile"
        class="w-full px-3 py-2.5 border border-border rounded text-sm focus:border-primary focus:ring-1 focus:ring-primary focus:outline-none"
        :disabled="isLoading"
      >
        <option
          v-for="(data, key) in RISK_PROFILE_LABELS"
          :key="key"
          :value="key"
        >
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

    <!-- Divider -->
    <div class="border-t border-border"></div>

    <!-- Action Buttons -->
    <div class="flex items-center justify-end gap-3">
      <Button type="button" variant="secondary" @click="handleCancel">
        Cancelar
      </Button>
      <Button type="submit" :loading="isLoading">
        {{ isLoading ? 'Salvando...' : 'Salvar Alterações' }}
      </Button>
    </div>
  </form>
</template>
