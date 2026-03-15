import { vi } from 'vitest'

export function setupChartMock() {
  vi.mock('chart.js/auto', () => {
    const MockChart = vi.fn(() => ({
      data: { labels: [], datasets: [{ data: [] }] },
      update: vi.fn(),
      destroy: vi.fn(),
    }))
    return { default: MockChart }
  })
}

export function createMockHookContext(id = 'test-chart', ariaLabel = 'Test chart') {
  const el = document.createElement('div')
  el.id = id
  el.innerHTML = '<canvas></canvas>'
  el.dataset.ariaLabel = ariaLabel
  el.dataset.label = 'Test'
  return {
    el,
    handleEvent: vi.fn(),
  }
}
