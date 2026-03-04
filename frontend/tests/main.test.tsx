import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock('react-dom/client', () => ({
  createRoot: vi.fn(() => ({
    render: vi.fn(),
  })),
}))

describe('main.tsx bootstrap', () => {
  beforeEach(() => {
    document.body.innerHTML = '<div id="root"></div>'
  })

  it('mounts the React app without crashing', async () => {
    await import('../src/main')  // importa il file che esegue il bootstrap

    const { createRoot } = await import('react-dom/client')
    expect(createRoot).toHaveBeenCalled()
  })
})