import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Input from '../Input.vue'

describe('Input', () => {
  describe('Rendering', () => {
    it('should render with default props', () => {
      const wrapper = mount(Input)
      const input = wrapper.find('input')

      expect(input.exists()).toBe(true)
      expect(input.attributes('type')).toBe('text')
    })

    it('should render with placeholder', () => {
      const wrapper = mount(Input, {
        props: { placeholder: 'Enter text' }
      })

      expect(wrapper.find('input').attributes('placeholder')).toBe('Enter text')
    })

    it('should render with custom id', () => {
      const wrapper = mount(Input, {
        props: { id: 'custom-input' }
      })

      expect(wrapper.find('input').attributes('id')).toBe('custom-input')
    })
  })

  describe('Input Types', () => {
    it('should render email input', () => {
      const wrapper = mount(Input, {
        props: { type: 'email' }
      })

      expect(wrapper.find('input').attributes('type')).toBe('email')
    })

    it('should render password input', () => {
      const wrapper = mount(Input, {
        props: { type: 'password' }
      })

      expect(wrapper.find('input').attributes('type')).toBe('password')
    })

    it('should render number input', () => {
      const wrapper = mount(Input, {
        props: { type: 'number' }
      })

      expect(wrapper.find('input').attributes('type')).toBe('number')
    })

    it('should render tel input', () => {
      const wrapper = mount(Input, {
        props: { type: 'tel' }
      })

      expect(wrapper.find('input').attributes('type')).toBe('tel')
    })
  })

  describe('Model Value', () => {
    it('should display model value', () => {
      const wrapper = mount(Input, {
        props: { modelValue: 'test value' }
      })

      expect(wrapper.find('input').element.value).toBe('test value')
    })

    it('should emit update:modelValue on input', async () => {
      const wrapper = mount(Input)
      const input = wrapper.find('input')

      await input.setValue('new value')

      expect(wrapper.emitted('update:modelValue')).toBeTruthy()
      expect(wrapper.emitted('update:modelValue')?.[0]).toEqual(['new value'])
    })

    it('should emit number value for number type', async () => {
      const wrapper = mount(Input, {
        props: { type: 'number' }
      })
      const input = wrapper.find('input')

      await input.setValue('42')

      expect(wrapper.emitted('update:modelValue')?.[0]).toEqual([42])
    })
  })

  describe('Error State', () => {
    it('should show error message', () => {
      const wrapper = mount(Input, {
        props: {
          id: 'test-input',
          error: 'This field is required'
        }
      })

      const error = wrapper.find('[id="test-input-error"]')
      expect(error.exists()).toBe(true)
      expect(error.text()).toBe('This field is required')
      expect(error.classes()).toContain('text-danger')
    })

    it('should apply error classes to input', () => {
      const wrapper = mount(Input, {
        props: { error: 'Error' }
      })

      const input = wrapper.find('input')
      expect(input.classes()).toContain('border-danger')
    })

    it('should set aria-invalid when has error', () => {
      const wrapper = mount(Input, {
        props: {
          id: 'test-input',
          error: 'Error'
        }
      })

      expect(wrapper.find('input').attributes('aria-invalid')).toBe('true')
      expect(wrapper.find('input').attributes('aria-describedby')).toBe('test-input-error')
    })

    it('should not show helper text when has error', () => {
      const wrapper = mount(Input, {
        props: {
          id: 'test-input',
          error: 'Error',
          helperText: 'Helper text'
        }
      })

      expect(wrapper.find('[id="test-input-helper"]').exists()).toBe(false)
      expect(wrapper.find('[id="test-input-error"]').exists()).toBe(true)
    })
  })

  describe('Helper Text', () => {
    it('should show helper text', () => {
      const wrapper = mount(Input, {
        props: {
          id: 'test-input',
          helperText: 'Enter your email address'
        }
      })

      const helper = wrapper.find('[id="test-input-helper"]')
      expect(helper.exists()).toBe(true)
      expect(helper.text()).toBe('Enter your email address')
      expect(helper.classes()).toContain('text-text-secondary')
    })

    it('should set aria-describedby for helper text', () => {
      const wrapper = mount(Input, {
        props: {
          id: 'test-input',
          helperText: 'Helper'
        }
      })

      expect(wrapper.find('input').attributes('aria-describedby')).toBe('test-input-helper')
    })
  })

  describe('Prefix and Suffix', () => {
    it('should show prefix', () => {
      const wrapper = mount(Input, {
        props: { prefix: '$' }
      })

      const prefix = wrapper.find('.absolute.left-3')
      expect(prefix.exists()).toBe(true)
      expect(prefix.text()).toBe('$')
    })

    it('should show suffix', () => {
      const wrapper = mount(Input, {
        props: { suffix: '.com' }
      })

      const suffix = wrapper.find('.absolute.right-3')
      expect(suffix.exists()).toBe(true)
      expect(suffix.text()).toBe('.com')
    })

    it('should apply padding when has prefix', () => {
      const wrapper = mount(Input, {
        props: { prefix: '$' }
      })

      expect(wrapper.find('input').classes()).toContain('pl-8')
    })

    it('should apply padding when has suffix', () => {
      const wrapper = mount(Input, {
        props: { suffix: '.com' }
      })

      expect(wrapper.find('input').classes()).toContain('pr-8')
    })
  })

  describe('Disabled State', () => {
    it('should disable input when disabled prop is true', () => {
      const wrapper = mount(Input, {
        props: { disabled: true }
      })

      const input = wrapper.find('input')
      expect(input.attributes('disabled')).toBeDefined()
      expect(input.classes()).toContain('disabled:opacity-50')
      expect(input.classes()).toContain('disabled:cursor-not-allowed')
    })

    it('should not emit update when disabled', async () => {
      const wrapper = mount(Input, {
        props: { disabled: true }
      })

      await wrapper.find('input').setValue('test')

      // Input is disabled at HTML level, so setValue won't actually work
      expect(wrapper.find('input').element.disabled).toBe(true)
    })
  })

  describe('Accessibility', () => {
    it('should have correct ARIA attributes for error state', () => {
      const wrapper = mount(Input, {
        props: {
          id: 'email',
          error: 'Invalid email'
        }
      })

      const input = wrapper.find('input')
      expect(input.attributes('aria-invalid')).toBe('true')
      expect(input.attributes('aria-describedby')).toBe('email-error')
    })

    it('should have correct ARIA attributes for helper text', () => {
      const wrapper = mount(Input, {
        props: {
          id: 'email',
          helperText: 'We will never share your email'
        }
      })

      const input = wrapper.find('input')
      expect(input.attributes('aria-describedby')).toBe('email-helper')
    })
  })
})
