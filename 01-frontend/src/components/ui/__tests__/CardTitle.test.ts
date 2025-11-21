import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import CardTitle from '../CardTitle.vue'

describe('CardTitle', () => {
  describe('Rendering', () => {
    it('should render as h3 element', () => {
      const wrapper = mount(CardTitle, {
        slots: { default: 'Card Title' }
      })

      expect(wrapper.find('h3').exists()).toBe(true)
      expect(wrapper.find('h3').text()).toBe('Card Title')
    })

    it('should render slot content', () => {
      const wrapper = mount(CardTitle, {
        slots: {
          default: 'Custom Title'
        }
      })

      expect(wrapper.text()).toBe('Custom Title')
    })
  })

  describe('Styling', () => {
    it('should apply correct CSS classes', () => {
      const wrapper = mount(CardTitle)

      const h3 = wrapper.find('h3')
      expect(h3.classes()).toContain('text-h3')
      expect(h3.classes()).toContain('font-semibold')
      expect(h3.classes()).toContain('text-text-primary')
    })
  })
})
