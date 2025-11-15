<script setup lang="ts">
/**
 * Dashboard Layout
 * Wraps all dashboard pages with Navbar
 */

import Navbar from '@/components/layout/Navbar.vue'
</script>

<template>
  <div class="min-h-screen bg-white">
    <!-- Navbar -->
    <Navbar />

    <!-- Main Content -->
    <main class="container-fluid py-6">
      <RouterView />
    </main>
  </div>
</template>
