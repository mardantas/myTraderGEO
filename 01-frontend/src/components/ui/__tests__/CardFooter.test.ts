import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import CardFooter from '../CardFooter.vue'

describe('CardFooter', () => {
  describe('Rendering', () => {
    it('should render with default props', () => {
      const wrapper = mount(CardFooter, {
        slots: { default: 'Footer content' }
      })

      expect(wrapper.text()).toBe('Footer content')
      expect(wrapper.find('div').exists()).toBe(true)
    })

    it('should render slot content', () => {
      const wrapper = mount(CardFooter, {
        slots: {
          default: '<button>Save</button>'
        }
      })

      expect(wrapper.html()).toContain('<button>Save</button>')
    })
  })

  describe('Styling', () => {
    it('should apply base padding classes', () => {
      const wrapper = mount(CardFooter)

      expect(wrapper.classes()).toContain('px-6')
      expect(wrapper.classes()).toContain('py-4')
    })

    it('should apply border by default', () => {
      const wrapper = mount(CardFooter)

      expect(wrapper.classes()).toContain('border-t')
      expect(wrapper.classes()).toContain('border-border')
    })
  })

  describe('No Border', () => {
    it('should not apply border when noBorder is true', () => {
      const wrapper = mount(CardFooter, {
        props: { noBorder: true }
      })

      expect(wrapper.classes()).not.toContain('border-t')
      expect(wrapper.classes()).not.toContain('border-border')
    })

    it('should apply border when noBorder is false', () => {
      const wrapper = mount(CardFooter, {
        props: { noBorder: false }
      })

      expect(wrapper.classes()).toContain('border-t')
      expect(wrapper.classes()).toContain('border-border')
    })
  })
})
