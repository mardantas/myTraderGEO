/**
 * Authentication Store (Pinia)
 * Based on: SEC-00 (JWT in memory, NOT localStorage)
 */

import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import type { User } from '@/types'
import * as authService from '@/services/auth.service'
import type { RegisterRequest, LoginRequest as ApiLoginRequest } from '@/types/api'
import { ApiError, getErrorMessage } from '@/services/api'
import { mapRiskProfileToApi, mapBillingPeriodToApi } from '@/types/api'

// Frontend types
export interface LoginCredentials {
  email: string
  password: string
  rememberMe?: boolean
}

export interface SignUpData {
  fullName: string
  displayName: string
  email: string
  password: string
  riskProfile: number
  subscriptionPlanId: number
  billingPeriod: number
}

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
  async function login(credentials: LoginCredentials): Promise<void> {
    isLoading.value = true
    error.value = null

    try {
      // Call backend login API
      const loginRequest: ApiLoginRequest = {
        email: credentials.email,
        password: credentials.password
      }

      const loginResponse = await authService.login(loginRequest)

      // Store token in memory
      token.value = loginResponse.token

      // Store in sessionStorage for persistence
      sessionStorage.setItem('auth_token', loginResponse.token)

      // Fetch full user profile
      const userProfile = await authService.getCurrentUser()
      user.value = authService.mapUserProfileToUser(userProfile)

      // Store user in sessionStorage
      sessionStorage.setItem('user', JSON.stringify(user.value))
    } catch (err) {
      error.value = getErrorMessage(err)
      throw err
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Sign up new user
   */
  async function signUp(data: SignUpData): Promise<void> {
    isLoading.value = true
    error.value = null

    try {
      // Prepare registration request for backend
      const registerRequest: RegisterRequest = {
        email: data.email,
        password: data.password,
        fullName: data.fullName,
        displayName: data.displayName,
        riskProfile: mapRiskProfileToApi(data.riskProfile),
        subscriptionPlanId: data.subscriptionPlanId,
        billingPeriod: mapBillingPeriodToApi(data.billingPeriod)
      }

      // Call backend register API
      await authService.register(registerRequest)

      // Backend doesn't return token on registration, so we need to login
      const loginRequest: ApiLoginRequest = {
        email: data.email,
        password: data.password
      }

      const loginResponse = await authService.login(loginRequest)

      // Store token
      token.value = loginResponse.token
      sessionStorage.setItem('auth_token', loginResponse.token)

      // Fetch full user profile
      const userProfile = await authService.getCurrentUser()
      user.value = authService.mapUserProfileToUser(userProfile)

      // Store user in sessionStorage
      sessionStorage.setItem('user', JSON.stringify(user.value))
    } catch (err) {
      error.value = getErrorMessage(err)
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
      const userProfile = await authService.getCurrentUser()
      user.value = authService.mapUserProfileToUser(userProfile)

      // Update sessionStorage
      sessionStorage.setItem('user', JSON.stringify(user.value))
    } catch (err) {
      // Handle token expiration
      if (err instanceof ApiError && err.status === 401) {
        logout()
        error.value = 'Sessão expirada. Faça login novamente.'
      } else {
        error.value = getErrorMessage(err)
      }
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
