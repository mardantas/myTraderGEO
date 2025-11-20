/**
 * Validation Schemas (Zod)
 * Based on: UXD-01 validation rules
 */

import { z } from 'zod'
import { RiskProfile, BillingPeriod } from '@/types'

// ===== Sign Up Schema =====

export const signUpSchema = z
  .object({
    fullName: z
      .string()
      .min(2, 'Nome completo deve ter no mínimo 2 caracteres')
      .max(100, 'Nome completo deve ter no máximo 100 caracteres')
      .regex(/^[a-zA-ZÀ-ÿ\s'-]+$/, 'Nome completo contém caracteres inválidos'),

    displayName: z
      .string()
      .min(2, 'Nome de exibição deve ter no mínimo 2 caracteres')
      .max(30, 'Nome de exibição deve ter no máximo 30 caracteres')
      .regex(/^[a-zA-Z0-9À-ÿ\s_-]+$/, 'Nome de exibição contém caracteres inválidos'),

    email: z
      .string()
      .email('Email inválido')
      .toLowerCase()
      .regex(/^[^\s@]+@[^\s@]+\.[^\s@]+$/, 'Email deve ter formato válido'),

    password: z
      .string()
      .min(8, 'Senha deve ter no mínimo 8 caracteres')
      .regex(/[a-z]/, 'Senha deve conter pelo menos uma letra minúscula')
      .regex(/[A-Z]/, 'Senha deve conter pelo menos uma letra maiúscula')
      .regex(/\d/, 'Senha deve conter pelo menos um número'),

    confirmPassword: z.string(),

    countryCode: z.string().default(''),

    phoneNumber: z.string().default(''),

    riskProfile: z.nativeEnum(RiskProfile, {
      errorMap: () => ({ message: 'Selecione um perfil de risco válido' })
    }),

    subscriptionPlanId: z
      .number()
      .int('ID do plano deve ser um número inteiro')
      .positive('ID do plano deve ser positivo'),

    billingPeriod: z.nativeEnum(BillingPeriod, {
      errorMap: () => ({ message: 'Selecione um período de cobrança válido' })
    }),

    termsAccepted: z.boolean().refine((val) => val === true, {
      message: 'Você deve aceitar os Termos & Condições'
    })
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: 'As senhas não coincidem',
    path: ['confirmPassword']
  })
  .refine(
    (data) => {
      const hasCountry = data.countryCode && data.countryCode.length > 0
      const hasPhone = data.phoneNumber && data.phoneNumber.length > 0
      // Both empty or both filled
      return (!hasCountry && !hasPhone) || (hasCountry && hasPhone)
    },
    {
      message: 'Se preencher o telefone, deve selecionar o país',
      path: ['phoneNumber']
    }
  )
  .refine(
    (data) => {
      if (!data.phoneNumber || data.phoneNumber.length === 0) return true
      return /^\d{10,15}$/.test(data.phoneNumber)
    },
    {
      message: 'Telefone deve conter entre 10 e 15 dígitos',
      path: ['phoneNumber']
    }
  )

export type SignUpFormData = z.infer<typeof signUpSchema>

// ===== Login Schema =====

export const loginSchema = z.object({
  email: z.string().email('Email inválido').toLowerCase(),

  password: z.string().min(1, 'Senha é obrigatória'),

  rememberMe: z.boolean().optional().default(false)
})

export type LoginFormData = z.infer<typeof loginSchema>

// ===== Edit Profile Schema =====

export const editProfileSchema = z.object({
  displayName: z
    .string()
    .min(2, 'Nome de exibição deve ter no mínimo 2 caracteres')
    .max(30, 'Nome de exibição deve ter no máximo 30 caracteres')
    .regex(/^[a-zA-Z0-9À-ÿ\s_-]+$/, 'Nome de exibição contém caracteres inválidos'),

  riskProfile: z.nativeEnum(RiskProfile, {
    errorMap: () => ({ message: 'Selecione um perfil de risco válido' })
  })
})

export type EditProfileFormData = z.infer<typeof editProfileSchema>

// ===== Add Phone Schema =====

export const addPhoneSchema = z.object({
  countryCode: z.string().regex(/^\+\d{1,4}$/, 'Código de país inválido'),

  phoneNumber: z.string().regex(/^\d{10,15}$/, 'Telefone deve conter entre 10 e 15 dígitos')
})

export type AddPhoneFormData = z.infer<typeof addPhoneSchema>

// ===== Verify Phone Schema =====

export const verifyPhoneSchema = z.object({
  code: z
    .string()
    .length(6, 'Código deve ter 6 dígitos')
    .regex(/^\d{6}$/, 'Código deve conter apenas números')
})

export type VerifyPhoneFormData = z.infer<typeof verifyPhoneSchema>

// ===== Change Phone Schema =====

export const changePhoneSchema = z.object({
  newCountryCode: z.string().regex(/^\+\d{1,4}$/, 'Código de país inválido'),

  newPhoneNumber: z.string().regex(/^\d{10,15}$/, 'Telefone deve conter entre 10 e 15 dígitos'),

  verificationCode: z
    .string()
    .length(6, 'Código deve ter 6 dígitos')
    .regex(/^\d{6}$/, 'Código deve conter apenas números')
})

export type ChangePhoneFormData = z.infer<typeof changePhoneSchema>

// ===== Password Strength Utility =====

export interface PasswordStrength {
  score: number // 0-4
  label: string
  color: string
}

export function calculatePasswordStrength(password: string): PasswordStrength {
  let score = 0

  if (!password) {
    return { score: 0, label: 'Muito Fraca', color: 'danger' }
  }

  // Length
  if (password.length >= 8) score++
  if (password.length >= 12) score++

  // Complexity
  if (/[a-z]/.test(password) && /[A-Z]/.test(password)) score++
  if (/\d/.test(password)) score++
  if (/[^a-zA-Z0-9]/.test(password)) score++

  // Cap at 4
  score = Math.min(score, 4)

  const labels: Record<number, { label: string; color: string }> = {
    0: { label: 'Muito Fraca', color: 'danger' },
    1: { label: 'Fraca', color: 'danger' },
    2: { label: 'Razoável', color: 'warning' },
    3: { label: 'Forte', color: 'info' },
    4: { label: 'Muito Forte', color: 'success' }
  }

  return { score, ...labels[score]! } as PasswordStrength
}
