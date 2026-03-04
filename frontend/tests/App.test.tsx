import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import App from '../src/App'

describe('App component', () => {
  it('renders the title', () => {
    render(<App />)
    expect(screen.getByText('Vite + React')).toBeInTheDocument()
  })

  it('renders the Counter component', () => {
    render(<App />)
    expect(screen.getByRole('button')).toBeInTheDocument()
  })
})