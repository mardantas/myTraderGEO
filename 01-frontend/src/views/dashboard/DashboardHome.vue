<script setup lang="ts">
/**
 * Dashboard Home Page
 * Based on: UXD-01 > Dashboard wireframe
 */

import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores'
import { Card, CardHeader, CardTitle, CardContent, Alert, Button } from '@/components/ui'
import { PlusIcon } from '@heroicons/vue/24/outline'

// Store & Route
const authStore = useAuthStore()
const route = useRoute()

// State
const showWelcome = ref(false)

// Computed
const user = computed(() => authStore.currentUser)

// Lifecycle
onMounted(() => {
  // Show welcome alert if coming from signup
  if (route.query.welcome === 'true') {
    showWelcome.value = true
    // Auto-dismiss after 5 seconds
    setTimeout(() => {
      showWelcome.value = false
    }, 5000)
  }
})

function dismissWelcome() {
  showWelcome.value = false
}
</script>

<template>
  <div class="max-w-7xl mx-auto space-y-6">
    <!-- Welcome Alert -->
    <Alert v-if="showWelcome" variant="success" dismissible @close="dismissWelcome">
      <strong>Bem-vindo ao myTraderGEO, {{ user?.displayName }}!</strong>
      <p class="mt-1">
        Sua conta foi criada com sucesso. Comece criando sua primeira estratégia de trading.
      </p>
    </Alert>

    <!-- Page Header -->
    <div>
      <h1 class="text-h1">Dashboard</h1>
      <p class="text-text-secondary mt-1">Visão geral das suas estratégias e performance</p>
    </div>

    <!-- Quick Stats -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
      <!-- Total Strategies -->
      <Card>
        <CardContent>
          <div class="flex items-center justify-between">
            <div>
              <p class="text-xs text-text-secondary uppercase tracking-wide">Estratégias Ativas</p>
              <p class="text-h2 font-bold text-text-primary mt-1">0</p>
            </div>
            <div class="w-12 h-12 bg-primary/10 rounded-full flex items-center justify-center">
              <span class="text-primary text-xl">📊</span>
            </div>
          </div>
        </CardContent>
      </Card>

      <!-- Total P&L -->
      <Card>
        <CardContent>
          <div class="flex items-center justify-between">
            <div>
              <p class="text-xs text-text-secondary uppercase tracking-wide">P&L Total</p>
              <p class="text-h2 font-bold text-text-primary mt-1">R$ 0,00</p>
            </div>
            <div class="w-12 h-12 bg-success/10 rounded-full flex items-center justify-center">
              <span class="text-success text-xl">💰</span>
            </div>
          </div>
        </CardContent>
      </Card>

      <!-- Active Alerts -->
      <Card>
        <CardContent>
          <div class="flex items-center justify-between">
            <div>
              <p class="text-xs text-text-secondary uppercase tracking-wide">Alertas Ativos</p>
              <p class="text-h2 font-bold text-text-primary mt-1">0</p>
            </div>
            <div class="w-12 h-12 bg-warning/10 rounded-full flex items-center justify-center">
              <span class="text-warning text-xl">🔔</span>
            </div>
          </div>
        </CardContent>
      </Card>

      <!-- Community Rank -->
      <Card>
        <CardContent>
          <div class="flex items-center justify-between">
            <div>
              <p class="text-xs text-text-secondary uppercase tracking-wide">Ranking Comunidade</p>
              <p class="text-h2 font-bold text-text-primary mt-1">-</p>
            </div>
            <div class="w-12 h-12 bg-info/10 rounded-full flex items-center justify-center">
              <span class="text-info text-xl">🏆</span>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>

    <!-- Empty State: No Strategies -->
    <Card>
      <CardContent>
        <div class="text-center py-12">
          <!-- Icon -->
          <div
            class="w-20 h-20 bg-surface rounded-full flex items-center justify-center mx-auto mb-4"
          >
            <span class="text-4xl">📈</span>
          </div>

          <!-- Title -->
          <h3 class="text-h3 font-semibold text-text-primary mb-2">Nenhuma Estratégia Criada</h3>

          <!-- Description -->
          <p class="text-text-secondary max-w-md mx-auto mb-6">
            Você ainda não criou nenhuma estratégia de trading. Comece criando sua primeira
            estratégia para acompanhar sua performance e receber alertas personalizados.
          </p>

          <!-- CTA Button -->
          <Button>
            <PlusIcon class="w-5 h-5" />
            Criar Primeira Estratégia
          </Button>
        </div>
      </CardContent>
    </Card>

    <!-- Recent Activity (placeholder) -->
    <Card>
      <CardHeader>
        <CardTitle>Atividade Recente</CardTitle>
      </CardHeader>
      <CardContent>
        <p class="text-text-secondary text-sm">Suas atividades recentes aparecerão aqui.</p>
      </CardContent>
    </Card>
  </div>
</template>
