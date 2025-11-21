<script setup lang="ts">
/**
 * Admin Panel Page
 * Main admin dashboard with tabs for different admin functions
 */

import { ref, computed } from 'vue'
import { useAuthStore } from '@/stores'
import { AdminSystemConfig, AdminUserManagement, AdminPlansManagement } from '@/components/admin'
import { Card, CardHeader, CardTitle, CardContent, Alert } from '@/components/ui'

// Store
const authStore = useAuthStore()

// State
const activeTab = ref<'system' | 'users' | 'plans'>('system')

// Computed
const user = computed(() => authStore.currentUser)
const isAdmin = computed(() => user.value?.role === 'Administrator')
const isModerator = computed(() => user.value?.role === 'Moderator' || isAdmin.value)

// Tab configuration
const tabs = [
  {
    id: 'system' as const,
    name: 'Configuração do Sistema',
    icon: '⚙️',
    requiredRole: 'Moderator',
    description: 'Taxas e limites do sistema'
  },
  {
    id: 'users' as const,
    name: 'Gestão de Usuários',
    icon: '👥',
    requiredRole: 'Administrator',
    description: 'Overrides de plano'
  },
  {
    id: 'plans' as const,
    name: 'Gestão de Planos',
    icon: '💳',
    requiredRole: 'Administrator',
    description: 'Criar e editar planos'
  }
]

// Check if user can access tab
function canAccessTab(tabRole: string): boolean {
  if (tabRole === 'Administrator') return isAdmin.value
  if (tabRole === 'Moderator') return isModerator.value
  return false
}
</script>

<template>
  <div class="max-w-7xl mx-auto space-y-6">
    <!-- Page Header -->
    <div>
      <h1 class="text-3xl font-bold">Painel Administrativo</h1>
      <p class="text-gray-600 dark:text-gray-400 mt-1">
        Gerenciamento e configuração do sistema
      </p>
    </div>

    <!-- Access Denied Alert (for non-admin/moderator users) -->
    <Alert v-if="!isModerator" variant="error">
      <strong>Acesso Negado</strong>
      <p class="mt-1">
        Você não tem permissão para acessar o painel administrativo. Esta área é restrita a moderadores e administradores.
      </p>
    </Alert>

    <!-- Admin Content (only for admin/moderator) -->
    <template v-else>
      <!-- Tabs Navigation -->
      <div class="border-b border-gray-200 dark:border-gray-700">
        <nav class="-mb-px flex space-x-8">
          <button
            v-for="tab in tabs"
            :key="tab.id"
            @click="activeTab = tab.id"
            :disabled="!canAccessTab(tab.requiredRole)"
            :class="[
              'py-4 px-1 border-b-2 font-medium text-sm transition-colors',
              activeTab === tab.id
                ? 'border-primary-600 text-primary-600 dark:text-primary-400'
                : canAccessTab(tab.requiredRole)
                ? 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300 dark:text-gray-400 dark:hover:text-gray-300'
                : 'border-transparent text-gray-300 cursor-not-allowed dark:text-gray-600'
            ]"
          >
            <span class="mr-2">{{ tab.icon }}</span>
            {{ tab.name }}
          </button>
        </nav>
      </div>

      <!-- Tab Content -->
      <div class="py-6">
        <!-- System Configuration Tab -->
        <div v-if="activeTab === 'system'" class="animate-fadeIn">
          <AdminSystemConfig />
        </div>

        <!-- User Management Tab -->
        <div v-else-if="activeTab === 'users'" class="animate-fadeIn">
          <Alert v-if="!isAdmin" variant="error" class="mb-6">
            <strong>Acesso Restrito</strong>
            <p class="mt-1">
              A gestão de usuários é exclusiva para administradores.
            </p>
          </Alert>
          <AdminUserManagement v-else />
        </div>

        <!-- Plans Management Tab -->
        <div v-else-if="activeTab === 'plans'" class="animate-fadeIn">
          <Alert v-if="!isAdmin" variant="error" class="mb-6">
            <strong>Acesso Restrito</strong>
            <p class="mt-1">
              A gestão de planos é exclusiva para administradores.
            </p>
          </Alert>
          <AdminPlansManagement v-else />
        </div>
      </div>

      <!-- Admin Info Card -->
      <Card class="bg-gradient-to-r from-purple-50 to-blue-50 dark:from-purple-950 dark:to-blue-950 border-purple-200 dark:border-purple-800">
        <CardHeader>
          <CardTitle class="text-sm">ℹ️ Informações do Administrador</CardTitle>
        </CardHeader>
        <CardContent class="text-sm space-y-2">
          <p><strong>Usuário:</strong> {{ user?.displayName }} ({{ user?.email.value }})</p>
          <p><strong>Função:</strong> {{ user?.role }}</p>
          <p class="text-xs text-gray-600 dark:text-gray-400 pt-2">
            <strong>Nota:</strong> Todas as alterações feitas através deste painel são registradas e auditadas. Use com responsabilidade.
          </p>
        </CardContent>
      </Card>
    </template>
  </div>
</template>

<style scoped>
.animate-fadeIn {
  animation: fadeIn 0.3s ease-in;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
