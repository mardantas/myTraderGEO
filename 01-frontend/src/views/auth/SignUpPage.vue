<script setup lang="ts">
/**
 * Sign Up Page
 * Based on: UXD-01 > WF-01: Sign Up
 */

import SignUpForm from '@/components/forms/SignUpForm.vue'
</script>

<template>
  <div class="min-h-screen bg-surface flex items-center justify-center p-4">
    <div class="w-full max-w-4xl my-8">
      <!-- Card -->
      <div class="bg-white rounded-lg shadow-md p-8">
        <!-- Logo & Title -->
        <div class="text-center mb-6">
          <h1 class="text-h2 font-bold text-primary mb-2">myTraderGEO</h1>
          <h2 class="text-h3">Criar sua Conta</h2>
          <p class="text-sm text-text-secondary mt-1">
            Comece sua jornada de trading geolocalizado
          </p>
        </div>

        <!-- Sign Up Form -->
        <SignUpForm />
      </div>
    </div>
  </div>
</template>
