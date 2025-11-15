<script setup lang="ts">
/**
 * Navbar Component
 * Based on: UXD-01 > Navbar wireframe
 */

import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores'
import { Badge, Button } from '@/components/ui'
import { BellIcon, UserCircleIcon, Cog6ToothIcon, ArrowRightOnRectangleIcon } from '@heroicons/vue/24/outline'
import { getInitials } from '@/lib/utils'

// Store
const authStore = useAuthStore()
const router = useRouter()

// State
const userMenuOpen = ref(false)

// Computed
const user = computed(() => authStore.currentUser)
const userInitials = computed(() => (user.value ? getInitials(user.value.fullName) : ''))

// Methods
function toggleUserMenu() {
  userMenuOpen.value = !userMenuOpen.value
}

function closeUserMenu() {
  userMenuOpen.value = false
}

function logout() {
  authStore.logout()
  router.push('/login')
}

// Market status (mock)
const marketStatus = computed(() => ({
  label: 'Mercado Aberto',
  color: 'success' as const,
}))
</script>

<template>
  <nav class="bg-white border-b border-border sticky top-0 z-50">
    <div class="container-fluid">
      <div class="flex items-center justify-between h-16">
        <!-- Logo & Nav Links -->
        <div class="flex items-center gap-8">
          <!-- Logo -->
          <router-link to="/dashboard" class="flex items-center gap-2">
            <div class="w-8 h-8 bg-primary rounded flex items-center justify-center">
              <span class="text-white font-bold text-sm">GT</span>
            </div>
            <span class="text-h4 font-bold text-text-primary hidden sm:block">
              myTraderGEO
            </span>
          </router-link>

          <!-- Nav Links (Desktop) -->
          <div class="hidden md:flex items-center gap-6">
            <router-link
              to="/dashboard"
              class="text-sm font-medium text-text-secondary hover:text-primary transition-colors"
              active-class="text-primary"
            >
              Dashboard
            </router-link>
            <router-link
              to="/strategies"
              class="text-sm font-medium text-text-secondary hover:text-primary transition-colors"
              active-class="text-primary"
            >
              Estratégias
            </router-link>
            <router-link
              to="/analytics"
              class="text-sm font-medium text-text-secondary hover:text-primary transition-colors"
              active-class="text-primary"
            >
              Análises
            </router-link>
            <router-link
              to="/community"
              class="text-sm font-medium text-text-secondary hover:text-primary transition-colors"
              active-class="text-primary"
            >
              Comunidade
            </router-link>
          </div>
        </div>

        <!-- Right Side: Status, Plan, Notifications, User Menu -->
        <div class="flex items-center gap-4">
          <!-- Market Status -->
          <Badge :variant="marketStatus.color">
            {{ marketStatus.label }}
          </Badge>

          <!-- User Plan -->
          <Badge v-if="user" variant="premium" class="hidden sm:inline-flex">
            {{ user.subscriptionPlan?.name || 'Básico' }}
          </Badge>

          <!-- Notifications -->
          <button
            type="button"
            class="relative p-2 text-text-secondary hover:text-primary transition-colors"
          >
            <BellIcon class="w-6 h-6" />
            <!-- Notification counter -->
            <span class="absolute top-1 right-1 w-2 h-2 bg-danger rounded-full"></span>
          </button>

          <!-- User Menu -->
          <div class="relative">
            <button
              type="button"
              class="flex items-center gap-2 p-2 rounded hover:bg-surface transition-colors"
              @click="toggleUserMenu"
            >
              <!-- Avatar -->
              <div class="w-8 h-8 bg-primary/10 rounded-full flex items-center justify-center">
                <span class="text-primary font-medium text-sm">
                  {{ userInitials }}
                </span>
              </div>
              <!-- Name (Desktop only) -->
              <span class="hidden lg:block text-sm font-medium text-text-primary">
                {{ user?.displayName }}
              </span>
            </button>

            <!-- Dropdown Menu -->
            <div
              v-if="userMenuOpen"
              class="absolute right-0 mt-2 w-56 bg-white rounded-lg shadow-lg border border-border py-1"
              @click="closeUserMenu"
            >
              <!-- User Info -->
              <div class="px-4 py-3 border-b border-border">
                <p class="text-sm font-medium text-text-primary">{{ user?.fullName }}</p>
                <p class="text-xs text-text-secondary truncate">{{ user?.email.value }}</p>
              </div>

              <!-- Menu Items -->
              <router-link
                to="/dashboard/profile"
                class="flex items-center gap-3 px-4 py-2 text-sm text-text-secondary hover:bg-surface hover:text-primary transition-colors"
              >
                <UserCircleIcon class="w-5 h-5" />
                Meu Perfil
              </router-link>

              <router-link
                to="/dashboard/settings"
                class="flex items-center gap-3 px-4 py-2 text-sm text-text-secondary hover:bg-surface hover:text-primary transition-colors"
              >
                <Cog6ToothIcon class="w-5 h-5" />
                Configurações
              </router-link>

              <div class="border-t border-border my-1"></div>

              <button
                type="button"
                class="w-full flex items-center gap-3 px-4 py-2 text-sm text-danger hover:bg-danger/10 transition-colors"
                @click="logout"
              >
                <ArrowRightOnRectangleIcon class="w-5 h-5" />
                Sair
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Click outside to close menu -->
    <div
      v-if="userMenuOpen"
      class="fixed inset-0 z-40"
      @click="closeUserMenu"
    ></div>
  </nav>
</template>
