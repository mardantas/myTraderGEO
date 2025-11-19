/**
 * API Types and DTOs
 * Types that match the backend API contracts
 */

// ===== Auth DTOs =====

/**
 * Register Request (POST /api/Auth/register)
 */
export interface RegisterRequest {
  email: string
  password: string
  fullName: string
  displayName: string
  riskProfile: number // 0=Conservador, 1=Moderado, 2=Agressivo
  subscriptionPlanId: number
  billingPeriod: number // 1=Monthly, 12=Annual
}

/**
 * Register Response
 */
export interface RegisterResponse {
  userId: string
  email: string
  message: string
}

/**
 * Login Request (POST /api/Auth/login)
 */
export interface LoginRequest {
  email: string
  password: string
}

/**
 * Login Response
 */
export interface LoginResponse {
  token: string
  email: string
  role: string // "Trader" | "Moderator" | "Administrator"
  message: string
}

// ===== User DTOs =====

/**
 * User Profile Response (GET /api/Users/me)
 */
export interface UserProfileResponse {
  id: string
  email: string
  fullName: string
  displayName: string
  role: string
  status: string
  riskProfile: string | null
  subscriptionPlanId: number | null
  billingPeriod: string | null
  createdAt: string
  lastLoginAt: string | null
}

// ===== Subscription Plan DTOs =====

/**
 * Plan Response (GET /api/Plans or GET /api/Plans/{id})
 */
export interface PlanResponse {
  id: number
  name: string
  description: string
  isActive: boolean
  features: PlanFeatures
  pricing: PlanPricing
}

export interface PlanFeatures {
  strategyLimit: number
  hasRealtimeData: boolean
  hasAdvancedAlerts: boolean
  hasConsultingTools: boolean
  hasCommunityAccess: boolean
}

export interface PlanPricing {
  monthlyPrice: number
  annualPrice: number
  currency: string
}

// ===== Mapping Helpers =====

/**
 * Map backend risk profile string to frontend enum
 */
export function mapRiskProfileFromApi(apiValue: string | null): number {
  const mapping: Record<string, number> = {
    Conservador: 0,
    Moderado: 1,
    Agressivo: 2
  }
  return apiValue ? (mapping[apiValue] ?? 1) : 1
}

/**
 * Map frontend risk profile enum to backend number
 */
export function mapRiskProfileToApi(frontendValue: number): number {
  // Frontend and backend use same values (0, 1, 2)
  return frontendValue
}

/**
 * Map backend billing period string to frontend enum
 */
export function mapBillingPeriodFromApi(apiValue: string | null): number {
  const mapping: Record<string, number> = {
    Monthly: 1,
    Annual: 12
  }
  return apiValue ? (mapping[apiValue] ?? 1) : 1
}

/**
 * Map frontend billing period enum to backend number
 */
export function mapBillingPeriodToApi(frontendValue: number): number {
  // Frontend and backend use same values (1, 12)
  return frontendValue
}

/**
 * Map backend user role string to frontend enum
 */
export function mapUserRoleFromApi(apiValue: string): string {
  // Backend uses same values as frontend
  return apiValue
}

/**
 * Map backend user status string to frontend enum
 */
export function mapUserStatusFromApi(apiValue: string): string {
  // Backend uses same values as frontend
  return apiValue
}
