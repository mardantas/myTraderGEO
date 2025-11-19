/**
 * Authentication Store (Pinia)
 * Based on: SEC-00 (JWT in memory, NOT localStorage)
 */

import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { User, LoginRequest, LoginResponse, SignUpRequest, SignUpResponse } from '@/types'

const API_URL = import.meta.env.VITE_API_URL

export const useAuthStore = defineStore('auth', () => {
  // ===== State =====
  const user = ref<User | null>(null)
  const token = ref<string | null>(null)
  const isLoading = ref(false)
  const error = ref<string | null>(null)

  // ===== Getters =====
  const isAuthenticated = computed(() => !!user.value && !!token.value)
  const currentUser = computed(() => user.value)

  // ===== Actions =====

  /**
   * Login user
   */
  async function login(credentials: LoginRequest): Promise<void> {
    isLoading.value = true
    error.value = null

    try {
      const response = await fetch(`${API_URL}/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(credentials)
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Erro ao fazer login')
      }

      const data: LoginResponse = await response.json()

      // Store token in memory (NOT localStorage per SEC-00)
      token.value = data.token
      user.value = data.user

      // Optionally store in sessionStorage for persistence across tabs (less secure but more UX)
      if (credentials.rememberMe) {
        sessionStorage.setItem('auth_token', data.token)
        sessionStorage.setItem('user', JSON.stringify(data.user))
      }
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Erro ao fazer login'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Sign up new user
   */
  async function signUp(data: SignUpRequest): Promise<void> {
    isLoading.value = true
    error.value = null

    try {
      const response = await fetch(`${API_URL}/auth/register`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
      })

      if (!response.ok) {
        const errorData = await response.json()
        throw new Error(errorData.message || 'Erro ao criar conta')
      }

      const responseData: SignUpResponse = await response.json()

      // Store token in memory
      token.value = responseData.token
      user.value = responseData.user

      // Store in sessionStorage for persistence
      sessionStorage.setItem('auth_token', responseData.token)
      sessionStorage.setItem('user', JSON.stringify(responseData.user))
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Erro ao criar conta'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Logout user
   */
  function logout(): void {
    // Clear state
    user.value = null
    token.value = null
    error.value = null

    // Clear sessionStorage
    sessionStorage.removeItem('auth_token')
    sessionStorage.removeItem('user')
  }

  /**
   * Restore session from sessionStorage (on app init)
   */
  function restoreSession(): void {
    const storedToken = sessionStorage.getItem('auth_token')
    const storedUser = sessionStorage.getItem('user')

    if (storedToken && storedUser) {
      try {
        token.value = storedToken
        user.value = JSON.parse(storedUser)
      } catch (err) {
        console.error('Failed to restore session:', err)
        logout()
      }
    }
  }

  /**
   * Fetch current user from API (verify token)
   */
  async function fetchCurrentUser(): Promise<void> {
    if (!token.value) {
      throw new Error('No token available')
    }

    isLoading.value = true
    error.value = null

    try {
      const response = await fetch(`${API_URL}/users/me`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token.value}`
        }
      })

      if (!response.ok) {
        if (response.status === 401) {
          // Token expired or invalid
          logout()
          throw new Error('Sessão expirada. Faça login novamente.')
        }
        const errorData = await response.json()
        throw new Error(errorData.message || 'Erro ao buscar usuário')
      }

      const data = await response.json()
      user.value = data.user

      // Update sessionStorage
      sessionStorage.setItem('user', JSON.stringify(data.user))
    } catch (err) {
      error.value = err instanceof Error ? err.message : 'Erro ao buscar usuário'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Update user in store (after profile update)
   */
  function updateUser(updatedUser: User): void {
    user.value = updatedUser
    sessionStorage.setItem('user', JSON.stringify(updatedUser))
  }

  // ===== Return =====
  return {
    // State
    user,
    token,
    isLoading,
    error,
    // Getters
    isAuthenticated,
    currentUser,
    // Actions
    login,
    signUp,
    logout,
    restoreSession,
    fetchCurrentUser,
    updateUser
  }
})
