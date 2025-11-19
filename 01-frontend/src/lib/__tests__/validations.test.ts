import { describe, it, expect } from 'vitest'
import { calculatePasswordStrength } from '../validations'

describe('Validation Utilities', () => {
  describe('calculatePasswordStrength()', () => {
    it('should return "Muito Fraca" for empty password', () => {
      const result = calculatePasswordStrength('')
      expect(result.score).toBe(0)
      expect(result.label).toBe('Muito Fraca')
      expect(result.color).toBe('danger')
    })

    it('should return "Fraca" for short password', () => {
      const result = calculatePasswordStrength('abc123')
      expect(result.score).toBe(1)
      expect(result.label).toBe('Fraca')
      expect(result.color).toBe('danger')
    })

    it('should return "Razoável" for password with length >= 8 and some complexity', () => {
      const result = calculatePasswordStrength('abcd1234')
      expect(result.score).toBe(2)
      expect(result.label).toBe('Razoável')
      expect(result.color).toBe('warning')
    })

    it('should return "Forte" for good password', () => {
      const result = calculatePasswordStrength('Abcd1234')
      expect(result.score).toBe(3)
      expect(result.label).toBe('Forte')
      expect(result.color).toBe('info')
    })

    it('should return "Muito Forte" for excellent password', () => {
      const result = calculatePasswordStrength('Abcd1234!')
      expect(result.score).toBe(4)
      expect(result.label).toBe('Muito Forte')
      expect(result.color).toBe('success')
    })

    it('should give score for length >= 8', () => {
      const result = calculatePasswordStrength('12345678')
      expect(result.score).toBeGreaterThanOrEqual(1)
    })

    it('should give extra score for length >= 12', () => {
      const short = calculatePasswordStrength('Abc123')
      const long = calculatePasswordStrength('Abc123456789')
      expect(long.score).toBeGreaterThan(short.score)
    })

    it('should give score for mixed case', () => {
      const lowercase = calculatePasswordStrength('abcd1234')
      const mixedCase = calculatePasswordStrength('Abcd1234')
      expect(mixedCase.score).toBeGreaterThan(lowercase.score)
    })

    it('should give score for numbers', () => {
      const noNumbers = calculatePasswordStrength('Abcdefgh')
      const withNumbers = calculatePasswordStrength('Abcd1234')
      expect(withNumbers.score).toBeGreaterThanOrEqual(noNumbers.score)
    })

    it('should give score for special characters', () => {
      const noSpecial = calculatePasswordStrength('Abcd1234')
      const withSpecial = calculatePasswordStrength('Abcd1234!')
      expect(withSpecial.score).toBeGreaterThan(noSpecial.score)
    })

    it('should cap score at 4', () => {
      const result = calculatePasswordStrength('SuperSecure123!@#$%^&*()LongPassword')
      expect(result.score).toBeLessThanOrEqual(4)
    })

    describe('Score Calculation Rules', () => {
      it('should calculate score 0: empty password', () => {
        expect(calculatePasswordStrength('').score).toBe(0)
      })

      it('should calculate score 1: short password with lowercase only', () => {
        expect(calculatePasswordStrength('abc').score).toBe(0)
        expect(calculatePasswordStrength('abcdefgh').score).toBe(1)
      })

      it('should calculate score 2: 8+ chars with mixed case', () => {
        expect(calculatePasswordStrength('Abcdefgh').score).toBe(2)
      })

      it('should calculate score 3: 8+ chars, mixed case, number', () => {
        expect(calculatePasswordStrength('Abcd1234').score).toBe(3)
      })

      it('should calculate score 4: 12+ chars, mixed case, number, special', () => {
        expect(calculatePasswordStrength('Abcd1234!@#$').score).toBe(4)
      })
    })

    describe('Real World Passwords', () => {
      it('should rate "password" as very weak', () => {
        const result = calculatePasswordStrength('password')
        expect(result.score).toBeLessThanOrEqual(1)
      })

      it('should rate "Password123" as strong', () => {
        const result = calculatePasswordStrength('Password123')
        expect(result.score).toBe(3)
      })

      it('should rate "P@ssw0rd!" as strong', () => {
        const result = calculatePasswordStrength('P@ssw0rd!')
        expect(result.score).toBe(4)
      })

      it('should rate "MySecureP@ssw0rd2024!" as very strong', () => {
        const result = calculatePasswordStrength('MySecureP@ssw0rd2024!')
        expect(result.score).toBe(4)
        expect(result.label).toBe('Muito Forte')
      })
    })
  })
})
