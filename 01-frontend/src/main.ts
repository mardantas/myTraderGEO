/**
 * Main App Entry Point
 */

import { createApp } from 'vue'
import { createPinia } from 'pinia'
import router from './router'
import App from './App.vue'

// Styles
import './style.css'

// Dev helpers (apenas em desenvolvimento)
import './lib/dev-helpers'

// Create app instance
const app = createApp(App)

// Create Pinia store
const pinia = createPinia()

// Use plugins
app.use(pinia)
app.use(router)

// Restore auth session on app init
import { useAuthStore } from '@/stores'
const authStore = useAuthStore()
authStore.restoreSession()

// Mount app
app.mount('#app')
