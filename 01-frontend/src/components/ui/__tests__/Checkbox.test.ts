import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Checkbox from '../Checkbox.vue'

describe('Checkbox', () => {
  describe('Rendering', () => {
    it('should render checkbox input', () => {
      const wrapper = mount(Checkbox)
      const input = wrapper.find('input[type="checkbox"]')

      expect(input.exists()).toBe(true)
    })

    it('should render label when slot content provided', () => {
      const wrapper = mount(Checkbox, {
        props: { id: 'terms' },
        slots: { default: 'I agree to terms' }
      })

      const label = wrapper.find('label')
      expect(label.exists()).toBe(true)
      expect(label.text()).toBe('I agree to terms')
      expect(label.attributes('for')).toBe('terms')
    })

    it('should not render label when no slot content', () => {
      const wrapper = mount(Checkbox)

      expect(wrapper.find('label').exists()).toBe(false)
    })
  })

  describe('Model Value', () => {
    it('should be unchecked by default', () => {
      const wrapper = mount(Checkbox)
      const input = wrapper.find('input')

      expect(input.element.checked).toBe(false)
    })

    it('should be checked when modelValue is true', () => {
      const wrapper = mount(Checkbox, {
        props: { modelValue: true }
      })
      const input = wrapper.find('input')

      expect(input.element.checked).toBe(true)
    })

    it('should emit update:modelValue on change', async () => {
      const wrapper = mount(Checkbox, {
        props: { modelValue: false }
      })
      const input = wrapper.find('input')

      await input.setValue(true)

      expect(wrapper.emitted('update:modelValue')).toBeTruthy()
      expect(wrapper.emitted('update:modelValue')?.[0]).toEqual([true])
    })

    it('should emit false when unchecked', async () => {
      const wrapper = mount(Checkbox, {
        props: { modelValue: true }
      })
      const input = wrapper.find('input')

      await input.setValue(false)

      expect(wrapper.emitted('update:modelValue')?.[0]).toEqual([false])
    })
  })

  describe('ID Attribute', () => {
    it('should set id on checkbox', () => {
      const wrapper = mount(Checkbox, {
        props: { id: 'agree' }
      })

      expect(wrapper.find('input').attributes('id')).toBe('agree')
    })

    it('should link label to checkbox via id', () => {
      const wrapper = mount(Checkbox, {
        props: { id: 'terms' },
        slots: { default: 'I agree' }
      })

      const label = wrapper.find('label')
      const input = wrapper.find('input')

      expect(label.attributes('for')).toBe('terms')
      expect(input.attributes('id')).toBe('terms')
    })
  })

  describe('Disabled State', () => {
    it('should disable checkbox when disabled prop is true', () => {
      const wrapper = mount(Checkbox, {
        props: { disabled: true }
      })

      const input = wrapper.find('input')
      expect(input.attributes('disabled')).toBeDefined()
      expect(input.classes()).toContain('disabled:opacity-50')
      expect(input.classes()).toContain('disabled:cursor-not-allowed')
    })

    it('should not be disabled by default', () => {
      const wrapper = mount(Checkbox)

      expect(wrapper.find('input').attributes('disabled')).toBeUndefined()
    })
  })

  describe('Error State', () => {
    it('should show error message', () => {
      const wrapper = mount(Checkbox, {
        props: {
          id: 'terms',
          error: 'You must accept the terms'
        }
      })

      const error = wrapper.find('[id="terms-error"]')
      expect(error.exists()).toBe(true)
      expect(error.text()).toBe('You must accept the terms')
      expect(error.classes()).toContain('text-danger')
    })

    it('should set aria-invalid when has error', () => {
      const wrapper = mount(Checkbox, {
        props: {
          id: 'terms',
          error: 'Required'
        }
      })

      const input = wrapper.find('input')
      expect(input.attributes('aria-invalid')).toBe('true')
      expect(input.attributes('aria-describedby')).toBe('terms-error')
    })

    it('should not show error by default', () => {
      const wrapper = mount(Checkbox, {
        props: { id: 'terms' }
      })

      expect(wrapper.find('[id="terms-error"]').exists()).toBe(false)
    })
  })

  describe('Styling', () => {
    it('should apply correct CSS classes to input', () => {
      const wrapper = mount(Checkbox)
      const input = wrapper.find('input')

      expect(input.classes()).toContain('w-4')
      expect(input.classes()).toContain('h-4')
      expect(input.classes()).toContain('text-primary')
      expect(input.classes()).toContain('border-border')
      expect(input.classes()).toContain('rounded')
    })

    it('should apply correct CSS classes to label', () => {
      const wrapper = mount(Checkbox, {
        props: { id: 'test' },
        slots: { default: 'Label' }
      })
      const label = wrapper.find('label')

      expect(label.classes()).toContain('text-sm')
      expect(label.classes()).toContain('text-text-primary')
      expect(label.classes()).toContain('cursor-pointer')
      expect(label.classes()).toContain('select-none')
    })
  })

  describe('Accessibility', () => {
    it('should have proper ARIA attributes for error state', () => {
      const wrapper = mount(Checkbox, {
        props: {
          id: 'terms',
          error: 'Error message'
        }
      })

      const input = wrapper.find('input')
      expect(input.attributes('aria-invalid')).toBe('true')
      expect(input.attributes('aria-describedby')).toBe('terms-error')
    })

    it('should not have aria-describedby when no error', () => {
      const wrapper = mount(Checkbox, {
        props: { id: 'terms' }
      })

      expect(wrapper.find('input').attributes('aria-describedby')).toBeUndefined()
    })
  })
})
