<script setup lang="ts">
/**
 * Edit Profile Page
 * Based on: UXD-01 > WF-04: Edit Profile
 */

import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { Card, CardHeader, CardTitle, CardContent, Alert } from '@/components/ui'
import EditProfileForm from '@/components/forms/EditProfileForm.vue'

// Router
const router = useRouter()

// State
const success = ref(false)

function handleSuccess() {
  success.value = true
  setTimeout(() => {
    router.push('/dashboard/profile')
  }, 2000)
}
</script>

<template>
  <div class="max-w-2xl mx-auto space-y-6">
    <!-- Page Header -->
    <div>
      <h1 class="text-h1">Editar Perfil</h1>
      <nav class="text-sm text-text-secondary mt-1">
        Dashboard &gt; Perfil &gt; Editar
      </nav>
    </div>

    <!-- Success Alert -->
    <Alert v-if="success" variant="success">
      <strong>Perfil atualizado com sucesso!</strong>
      <p class="mt-1">Você será redirecionado em instantes...</p>
    </Alert>

    <!-- Edit Form Card -->
    <Card>
      <CardHeader>
        <CardTitle>Editar Perfil</CardTitle>
      </CardHeader>
      <CardContent>
        <EditProfileForm :on-success="handleSuccess" />
      </CardContent>
    </Card>
  </div>
</template>
