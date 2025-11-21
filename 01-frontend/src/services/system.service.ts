/**
 * System Configuration Service (Admin)
 * Handles system configuration API calls for administrators and moderators
 */

import { apiGet, apiPut } from './api'
import type {
  SystemConfigResponse,
  UpdateSystemConfigRequest,
  UpdateSystemConfigResponse
} from '@/types/api'

/**
 * Get current system configuration (Moderator+ only)
 * Includes fees and limits
 */
export async function getSystemConfig(): Promise<SystemConfigResponse> {
  return apiGet<SystemConfigResponse>('/api/System/config')
}

/**
 * Update system configuration (Admin only)
 * @param data - System configuration parameters to update (all fields optional)
 */
export async function updateSystemConfig(
  data: UpdateSystemConfigRequest
): Promise<UpdateSystemConfigResponse> {
  return apiPut<UpdateSystemConfigResponse, UpdateSystemConfigRequest>('/api/System/config', data)
}
