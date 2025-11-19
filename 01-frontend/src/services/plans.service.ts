/**
 * Subscription Plans Service
 * Handles subscription plan API calls
 */

import { apiGet } from './api'
import type { PlanResponse } from '@/types/api'
import type { SubscriptionPlan } from '@/types'
import { BillingPeriod } from '@/types'

/**
 * Get all subscription plans
 */
export async function getPlans(): Promise<PlanResponse[]> {
  return apiGet<PlanResponse[]>('/api/Plans')
}

/**
 * Get specific plan by ID
 */
export async function getPlan(id: number): Promise<PlanResponse> {
  return apiGet<PlanResponse>(`/api/Plans/${id}`)
}

/**
 * Map API plan to frontend SubscriptionPlan type
 */
export function mapPlanToSubscriptionPlan(plan: PlanResponse): SubscriptionPlan {
  return {
    id: plan.id,
    name: plan.name,
    price: plan.pricing.monthlyPrice, // Default to monthly
    billingPeriod: BillingPeriod.Monthly,
    strategyLimit: plan.features.strategyLimit === 0 ? null : plan.features.strategyLimit,
    hasRealtimeData: plan.features.hasRealtimeData,
    hasAdvancedAlerts: plan.features.hasAdvancedAlerts,
    hasConsultingTools: plan.features.hasConsultingTools,
    hasCommunityAccess: plan.features.hasCommunityAccess,
    isActive: plan.isActive
  }
}

/**
 * Get plan price for specific billing period
 */
export function getPlanPrice(plan: PlanResponse, billingPeriod: BillingPeriod): number {
  return billingPeriod === BillingPeriod.Annual
    ? plan.pricing.annualPrice
    : plan.pricing.monthlyPrice
}
