/**
 * Authentication Service
 * Handles user authentication API calls
 */

import { apiPost, apiGet } from './api'
import type {
  RegisterRequest,
  RegisterResponse,
  LoginRequest,
  LoginResponse,
  UserProfileResponse
} from '@/types/api'
import type { User } from '@/types'
import {
  mapRiskProfileFromApi,
  mapBillingPeriodFromApi,
  mapUserRoleFromApi,
  mapUserStatusFromApi
} from '@/types/api'
import { RiskProfile, UserRole, UserStatus, BillingPeriod } from '@/types'

/**
 * Register a new trader
 */
export async function register(data: RegisterRequest): Promise<RegisterResponse> {
  return apiPost<RegisterResponse, RegisterRequest>('/api/Auth/register', data)
}

/**
 * Login user
 */
export async function login(data: LoginRequest): Promise<LoginResponse> {
  return apiPost<LoginResponse, LoginRequest>('/api/Auth/login', data)
}

/**
 * Get current user profile
 * Requires authentication
 */
export async function getCurrentUser(): Promise<UserProfileResponse> {
  return apiGet<UserProfileResponse>('/api/Users/me')
}

/**
 * Map API user profile to frontend User type
 */
export function mapUserProfileToUser(profile: UserProfileResponse): User {
  return {
    id: parseInt(profile.id) || 0,
    fullName: profile.fullName,
    displayName: profile.displayName,
    email: { value: profile.email },
    passwordHash: '', // Not returned by API
    phoneNumber: null, // TODO: Add when backend supports phone
    isPhoneVerified: false,
    role: mapUserRoleFromApi(profile.role) as UserRole,
    riskProfile: profile.riskProfile
      ? (mapRiskProfileFromApi(profile.riskProfile) as unknown as RiskProfile)
      : RiskProfile.Moderate,
    status: mapUserStatusFromApi(profile.status) as UserStatus,
    subscriptionPlanId: profile.subscriptionPlanId ?? 1,
    subscriptionPlan: undefined,
    billingPeriod: profile.billingPeriod
      ? (mapBillingPeriodFromApi(profile.billingPeriod) as unknown as BillingPeriod)
      : BillingPeriod.Monthly,
    planOverride: null,
    createdAt: profile.createdAt,
    lastLoginAt: profile.lastLoginAt || new Date().toISOString()
  }
}
