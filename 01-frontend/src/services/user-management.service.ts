/**
 * User Management Service (Admin)
 * Handles user management API calls for administrators
 */

import { apiPost, apiDelete } from './api'
import type {
  GrantPlanOverrideRequest,
  GrantPlanOverrideResponse,
  RevokePlanOverrideResponse
} from '@/types/api'

/**
 * Grant plan override to a user (Admin only)
 * @param userId - User ID (GUID)
 * @param data - Plan override details
 */
export async function grantPlanOverride(
  userId: string,
  data: GrantPlanOverrideRequest
): Promise<GrantPlanOverrideResponse> {
  return apiPost<GrantPlanOverrideResponse, GrantPlanOverrideRequest>(
    `/api/Users/${userId}/plan-override`,
    data
  )
}

/**
 * Revoke plan override from a user (Admin only)
 * @param userId - User ID (GUID)
 */
export async function revokePlanOverride(userId: string): Promise<RevokePlanOverrideResponse> {
  return apiDelete<RevokePlanOverrideResponse>(`/api/Users/${userId}/plan-override`)
}
