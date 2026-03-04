import { describe, it, expect } from 'vitest'
import { render, fireEvent, screen } from '@testing-library/react'
import Counter from '../src/Counter'

describe('Counter', () => {
  it('increments count when button is clicked', () => {
    render(<Counter />)

    const button = screen.getByRole('button', { name: /count is 0/i })
    expect(button).toBeDefined()

    fireEvent.click(button)
    expect(button.textContent).toBe('count is 1')

    fireEvent.click(button)
    expect(button.textContent).toBe('count is 2')

    fireEvent.click(button)
    expect(button.textContent).toBe('count is 3')

    fireEvent.click(button)
    expect(button.textContent).toBe('count is 4')

    fireEvent.click(button)
    expect(button.textContent).toBe('count is 5')

    fireEvent.click(button)
    expect(button.textContent).toBe('count is 6')
  })
})