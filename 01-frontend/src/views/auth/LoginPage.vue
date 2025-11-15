<script setup lang="ts">
/**
 * Login Page
 * Based on: UXD-01 > WF-02: Login
 */

import LoginForm from '@/components/forms/LoginForm.vue'
</script>

<template>
  <div class="min-h-screen bg-surface flex items-center justify-center p-4">
    <div class="w-full max-w-md">
      <!-- Card -->
      <div class="bg-white rounded-lg shadow-md p-8">
        <!-- Logo & Title -->
        <div class="text-center mb-6">
          <h1 class="text-h2 font-bold text-primary mb-2">myTraderGEO</h1>
          <h2 class="text-h3">Entrar na sua conta</h2>
        </div>

        <!-- Login Form -->
        <LoginForm />
      </div>
    </div>
  </div>
</template>
