/**
 * User Domain Types
 * Based on: DE-01-EPIC-01-A-User-Management-Domain-Model.md
 */

// ===== Enums =====

export enum UserRole {
  Trader = 'Trader',
  Consultant = 'Consultant',
  Moderator = 'Moderator',
  Administrator = 'Administrator',
}

export enum RiskProfile {
  Conservative = 'Conservative',
  Moderate = 'Moderate',
  Aggressive = 'Aggressive',
}

export enum UserStatus {
  Active = 'Active',
  Inactive = 'Inactive',
  Suspended = 'Suspended',
  PendingVerification = 'PendingVerification',
}

export enum BillingPeriod {
  Monthly = 'Monthly',
  Annual = 'Annual',
}

// ===== Value Objects =====

export interface Email {
  value: string
}

export interface PhoneNumber {
  countryCode: string
  number: string
}

// ===== Entities =====

export interface SubscriptionPlan {
  id: number
  name: string
  price: number
  billingPeriod: BillingPeriod
  strategyLimit: number | null // null = unlimited
  hasRealtimeData: boolean
  hasAdvancedAlerts: boolean
  hasConsultingTools: boolean
  hasCommunityAccess: boolean
  isActive: boolean
}

export interface PlanOverride {
  reason: string
  expiresAt: string | null // ISO date or null for permanent
  overriddenFeatures: string[]
}

export interface User {
  id: number
  fullName: string
  displayName: string
  email: Email
  passwordHash: string
  phoneNumber: PhoneNumber | null
  isPhoneVerified: boolean
  role: UserRole
  riskProfile: RiskProfile
  status: UserStatus
  subscriptionPlanId: number
  subscriptionPlan?: SubscriptionPlan
  billingPeriod: BillingPeriod
  planOverride?: PlanOverride | null
  createdAt: string // ISO date
  lastLoginAt: string | null // ISO date
}

// ===== API Request/Response Types =====

// Sign Up
export interface SignUpRequest {
  fullName: string
  displayName: string
  email: string
  password: string
  phoneNumber?: PhoneNumber
  riskProfile: RiskProfile
  subscriptionPlanId: number
  billingPeriod: BillingPeriod
  termsAccepted: boolean
}

export interface SignUpResponse {
  user: User
  token: string
}

// Login
export interface LoginRequest {
  email: string
  password: string
  rememberMe?: boolean
}

export interface LoginResponse {
  user: User
  token: string
}

// Get Current User
export interface GetCurrentUserResponse {
  user: User
}

// Update Profile
export interface UpdateProfileRequest {
  displayName?: string
  riskProfile?: RiskProfile
}

export interface UpdateProfileResponse {
  user: User
}

// Phone Management
export interface AddPhoneRequest {
  phoneNumber: PhoneNumber
}

export interface VerifyPhoneRequest {
  code: string
}

export interface ChangePhoneRequest {
  newPhoneNumber: PhoneNumber
}

// Upgrade Subscription
export interface UpgradeSubscriptionRequest {
  subscriptionPlanId: number
  billingPeriod: BillingPeriod
}

export interface UpgradeSubscriptionResponse {
  user: User
  checkoutUrl?: string // For payment processing
}

// ===== Form Types =====

export interface SignUpFormData {
  fullName: string
  displayName: string
  email: string
  password: string
  confirmPassword: string
  phoneNumber: string // formatted as string in form
  countryCode: string
  riskProfile: RiskProfile
  subscriptionPlanId: number
  billingPeriod: BillingPeriod
  termsAccepted: boolean
}

export interface LoginFormData {
  email: string
  password: string
  rememberMe: boolean
}

export interface EditProfileFormData {
  displayName: string
  riskProfile: RiskProfile
}

export interface AddPhoneFormData {
  countryCode: string
  phoneNumber: string
}

export interface VerifyPhoneFormData {
  code: string
}

export interface ChangePhoneFormData {
  currentPhoneNumber: string
  newCountryCode: string
  newPhoneNumber: string
  verificationCode: string
}

// ===== Label Mappings =====

export const USER_ROLE_LABELS: Record<UserRole, { label: string; color: string }> = {
  [UserRole.Trader]: { label: 'Trader', color: 'blue' },
  [UserRole.Consultant]: { label: 'Consultor', color: 'purple' },
  [UserRole.Moderator]: { label: 'Moderador', color: 'orange' },
  [UserRole.Administrator]: { label: 'Administrador', color: 'red' },
}

export const RISK_PROFILE_LABELS: Record<RiskProfile, { label: string; description: string; color: string }> = {
  [RiskProfile.Conservative]: {
    label: 'Conservador',
    description: 'Prefiro segurança e retornos estáveis',
    color: 'green',
  },
  [RiskProfile.Moderate]: {
    label: 'Moderado',
    description: 'Balanço entre risco e retorno',
    color: 'yellow',
  },
  [RiskProfile.Aggressive]: {
    label: 'Agressivo',
    description: 'Busco máximo retorno, aceito alto risco',
    color: 'red',
  },
}

export const USER_STATUS_LABELS: Record<UserStatus, { label: string; color: string }> = {
  [UserStatus.Active]: { label: 'Ativo', color: 'green' },
  [UserStatus.Inactive]: { label: 'Inativo', color: 'gray' },
  [UserStatus.Suspended]: { label: 'Suspenso', color: 'red' },
  [UserStatus.PendingVerification]: { label: 'Pendente de Verificação', color: 'orange' },
}

export const BILLING_PERIOD_LABELS: Record<BillingPeriod, string> = {
  [BillingPeriod.Monthly]: 'Mensal',
  [BillingPeriod.Annual]: 'Anual',
}

// ===== Helper Types =====

export type Plan = SubscriptionPlan & {
  recommended?: boolean
  monthlyPrice: number
  annualPrice: number
  features: {
    realtimeData: boolean
    advancedAlerts: boolean
    consultingTools: boolean
    communityAccess: boolean
  }
}
