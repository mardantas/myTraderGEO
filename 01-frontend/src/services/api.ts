/**
 * Base API Client
 * Handles HTTP requests with authentication and error handling
 */

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000'

/**
 * RFC 7807 Problem Details error structure
 */
export interface ProblemDetails {
  type: string
  title: string
  status: number
  detail: string
  errors?: Record<string, string[]>
  traceId?: string
}

/**
 * API Error class
 */
export class ApiError extends Error {
  constructor(
    public status: number,
    public problemDetails: ProblemDetails | null,
    message: string
  ) {
    super(message)
    this.name = 'ApiError'
  }
}

/**
 * Get auth token from storage
 */
function getAuthToken(): string | null {
  return sessionStorage.getItem('auth_token')
}

/**
 * Base fetch wrapper with authentication and error handling
 */
async function apiFetch<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const url = `${API_URL}${endpoint}`

  // Prepare headers
  const headers: Record<string, string> = {
    'Content-Type': 'application/json'
  }

  // Add custom headers
  if (options.headers) {
    Object.assign(headers, options.headers)
  }

  // Add auth token if available
  const token = getAuthToken()
  if (token) {
    headers['Authorization'] = `Bearer ${token}`
  }

  // Make request
  const response = await fetch(url, {
    ...options,
    headers
  })

  // Handle response
  if (!response.ok) {
    await handleErrorResponse(response)
  }

  // Parse JSON response
  if (response.status === 204) {
    return null as T
  }

  const data = await response.json()
  return data as T
}

/**
 * Handle error responses
 */
async function handleErrorResponse(response: Response): Promise<never> {
  let problemDetails: ProblemDetails | null = null
  let errorMessage = 'An error occurred'

  try {
    const data = await response.json()

    // Check if it's RFC 7807 Problem Details format
    if (data.type && data.title && data.status) {
      problemDetails = data as ProblemDetails
      errorMessage = problemDetails.detail || problemDetails.title
    } else if (data.error) {
      // Simple error format (404 responses)
      errorMessage = data.error
    } else if (data.message) {
      errorMessage = data.message
    }
  } catch {
    // If response is not JSON, use status text
    errorMessage = response.statusText || `Error ${response.status}`
  }

  throw new ApiError(response.status, problemDetails, errorMessage)
}

/**
 * GET request
 */
export async function apiGet<T>(endpoint: string): Promise<T> {
  return apiFetch<T>(endpoint, {
    method: 'GET'
  })
}

/**
 * POST request
 */
export async function apiPost<T, D = unknown>(endpoint: string, data?: D): Promise<T> {
  return apiFetch<T>(endpoint, {
    method: 'POST',
    body: data ? JSON.stringify(data) : undefined
  })
}

/**
 * PUT request
 */
export async function apiPut<T, D = unknown>(endpoint: string, data?: D): Promise<T> {
  return apiFetch<T>(endpoint, {
    method: 'PUT',
    body: data ? JSON.stringify(data) : undefined
  })
}

/**
 * PATCH request
 */
export async function apiPatch<T, D = unknown>(endpoint: string, data?: D): Promise<T> {
  return apiFetch<T>(endpoint, {
    method: 'PATCH',
    body: data ? JSON.stringify(data) : undefined
  })
}

/**
 * DELETE request
 */
export async function apiDelete<T>(endpoint: string): Promise<T> {
  return apiFetch<T>(endpoint, {
    method: 'DELETE'
  })
}

/**
 * Extract validation errors from Problem Details
 */
export function extractValidationErrors(error: ApiError): Record<string, string> | null {
  if (!error.problemDetails?.errors) {
    return null
  }

  const validationErrors: Record<string, string> = {}

  for (const [field, messages] of Object.entries(error.problemDetails.errors)) {
    // Take first error message for each field
    validationErrors[field] = messages[0] || 'Invalid value'
  }

  return validationErrors
}

/**
 * Get user-friendly error message
 */
export function getErrorMessage(error: unknown): string {
  if (error instanceof ApiError) {
    return error.message
  }

  if (error instanceof Error) {
    return error.message
  }

  return 'An unexpected error occurred'
}
