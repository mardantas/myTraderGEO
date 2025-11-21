import { describe, it, expect, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import Button from '../Button.vue'

describe('Button', () => {
  describe('Rendering', () => {
    it('should render with default props', () => {
      const wrapper = mount(Button, {
        slots: {
          default: 'Click me'
        }
      })

      expect(wrapper.text()).toBe('Click me')
      expect(wrapper.attributes('type')).toBe('button')
      expect(wrapper.classes()).toContain('bg-primary')
      expect(wrapper.classes()).toContain('h-11') // md size
    })

    it('should render slot content', () => {
      const wrapper = mount(Button, {
        slots: {
          default: '<span>Custom Content</span>'
        }
      })

      expect(wrapper.html()).toContain('Custom Content')
    })
  })

  describe('Variants', () => {
    it('should apply primary variant classes', () => {
      const wrapper = mount(Button, {
        props: { variant: 'primary' }
      })

      expect(wrapper.classes()).toContain('bg-primary')
      // Note: text-white is applied via scoped CSS, not class binding
    })

    it('should apply secondary variant classes', () => {
      const wrapper = mount(Button, {
        props: { variant: 'secondary' }
      })

      expect(wrapper.classes()).toContain('border-2')
      expect(wrapper.classes()).toContain('border-primary')
    })

    it('should apply danger variant classes', () => {
      const wrapper = mount(Button, {
        props: { variant: 'danger' }
      })

      expect(wrapper.classes()).toContain('bg-danger')
    })

    it('should apply success variant classes', () => {
      const wrapper = mount(Button, {
        props: { variant: 'success' }
      })

      expect(wrapper.classes()).toContain('bg-success')
    })

    it('should apply ghost variant classes', () => {
      const wrapper = mount(Button, {
        props: { variant: 'ghost' }
      })

      expect(wrapper.classes()).toContain('bg-transparent')
    })

    it('should apply link variant classes', () => {
      const wrapper = mount(Button, {
        props: { variant: 'link' }
      })

      expect(wrapper.classes()).toContain('underline-offset-4')
    })
  })

  describe('Sizes', () => {
    it('should apply small size classes', () => {
      const wrapper = mount(Button, {
        props: { size: 'sm' }
      })

      expect(wrapper.classes()).toContain('h-9')
      expect(wrapper.classes()).toContain('px-4')
    })

    it('should apply medium size classes', () => {
      const wrapper = mount(Button, {
        props: { size: 'md' }
      })

      expect(wrapper.classes()).toContain('h-11')
      expect(wrapper.classes()).toContain('px-5')
    })

    it('should apply large size classes', () => {
      const wrapper = mount(Button, {
        props: { size: 'lg' }
      })

      expect(wrapper.classes()).toContain('h-12')
      expect(wrapper.classes()).toContain('px-7')
    })

    it('should apply icon size classes', () => {
      const wrapper = mount(Button, {
        props: { size: 'icon' }
      })

      expect(wrapper.classes()).toContain('h-9')
      expect(wrapper.classes()).toContain('w-9')
    })
  })

  describe('Loading State', () => {
    it('should show loading spinner when loading is true', () => {
      const wrapper = mount(Button, {
        props: { loading: true },
        slots: { default: 'Loading' }
      })

      expect(wrapper.find('svg').exists()).toBe(true)
      expect(wrapper.find('svg').classes()).toContain('animate-spin')
    })

    it('should disable button when loading', () => {
      const wrapper = mount(Button, {
        props: { loading: true }
      })

      expect(wrapper.attributes('disabled')).toBeDefined()
    })

    it('should not show loading spinner when loading is false', () => {
      const wrapper = mount(Button, {
        props: { loading: false },
        slots: { default: 'Click me' }
      })

      expect(wrapper.find('svg').exists()).toBe(false)
    })
  })

  describe('Disabled State', () => {
    it('should disable button when disabled prop is true', () => {
      const wrapper = mount(Button, {
        props: { disabled: true }
      })

      expect(wrapper.attributes('disabled')).toBeDefined()
      expect(wrapper.classes()).toContain('disabled:opacity-50')
      expect(wrapper.classes()).toContain('disabled:cursor-not-allowed')
    })

    it('should not trigger click when disabled', async () => {
      const onClick = vi.fn()
      const wrapper = mount(Button, {
        props: { disabled: true },
        attrs: { onClick }
      })

      await wrapper.trigger('click')
      expect(onClick).not.toHaveBeenCalled()
    })
  })

  describe('Full Width', () => {
    it('should apply full width class when fullWidth is true', () => {
      const wrapper = mount(Button, {
        props: { fullWidth: true }
      })

      expect(wrapper.classes()).toContain('w-full')
    })

    it('should not apply full width class when fullWidth is false', () => {
      const wrapper = mount(Button, {
        props: { fullWidth: false }
      })

      expect(wrapper.classes()).not.toContain('w-full')
    })
  })

  describe('Button Type', () => {
    it('should set type attribute to submit', () => {
      const wrapper = mount(Button, {
        props: { type: 'submit' }
      })

      expect(wrapper.attributes('type')).toBe('submit')
    })

    it('should set type attribute to reset', () => {
      const wrapper = mount(Button, {
        props: { type: 'reset' }
      })

      expect(wrapper.attributes('type')).toBe('reset')
    })
  })

  describe('Events', () => {
    it('should emit click event when clicked', async () => {
      const onClick = vi.fn()
      const wrapper = mount(Button, {
        attrs: { onClick }
      })

      await wrapper.trigger('click')
      expect(onClick).toHaveBeenCalledTimes(1)
    })

    it('should not emit click when disabled', async () => {
      const onClick = vi.fn()
      const wrapper = mount(Button, {
        props: { disabled: true },
        attrs: { onClick }
      })

      await wrapper.trigger('click')
      expect(onClick).not.toHaveBeenCalled()
    })
  })
})
