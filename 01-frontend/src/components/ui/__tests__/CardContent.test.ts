import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import CardContent from '../CardContent.vue'

describe('CardContent', () => {
  describe('Rendering', () => {
    it('should render with default props', () => {
      const wrapper = mount(CardContent, {
        slots: { default: 'Content here' }
      })

      expect(wrapper.text()).toBe('Content here')
      expect(wrapper.find('div').exists()).toBe(true)
    })

    it('should render slot content', () => {
      const wrapper = mount(CardContent, {
        slots: {
          default: '<p>Custom content</p>'
        }
      })

      expect(wrapper.html()).toContain('<p>Custom content</p>')
    })
  })

  describe('Styling', () => {
    it('should apply padding classes', () => {
      const wrapper = mount(CardContent)

      expect(wrapper.classes()).toContain('px-6')
      expect(wrapper.classes()).toContain('py-4')
    })
  })
})
