import { describe, it, expect, vi, beforeEach } from 'vitest'

// Mock chart.js/auto before importing the hook
vi.mock('chart.js/auto', () => {
  const MockChart = vi.fn().mockImplementation(() => ({
    data: { labels: [], datasets: [{ data: [] }] },
    update: vi.fn(),
    destroy: vi.fn(),
  }))
  return { default: MockChart }
})

import BarChart from '../bar_chart'

function createMockHookContext(innerHTML = '<canvas></canvas>') {
  const el = document.createElement('div')
  el.innerHTML = innerHTML
  el.id = 'test-bar-chart'
  el.dataset.ariaLabel = 'Test bar chart'
  return {
    el,
    handleEvent: vi.fn(),
    chart: null,
  }
}

describe('BarChart hook', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('has a mounted method', () => {
    expect(typeof BarChart.mounted).toBe('function')
  })

  it('has a destroyed method', () => {
    expect(typeof BarChart.destroyed).toBe('function')
  })

  it('sets role="img" on the canvas after mount', () => {
    const ctx = createMockHookContext()
    BarChart.mounted.call(ctx)

    const canvas = ctx.el.querySelector('canvas')
    expect(canvas.getAttribute('role')).toBe('img')
  })

  it('sets aria-label on the canvas from dataset after mount', () => {
    const ctx = createMockHookContext()
    BarChart.mounted.call(ctx)

    const canvas = ctx.el.querySelector('canvas')
    expect(canvas.getAttribute('aria-label')).toBe('Test bar chart')
  })

  it('falls back to default aria-label when none provided', () => {
    const ctx = createMockHookContext()
    delete ctx.el.dataset.ariaLabel
    BarChart.mounted.call(ctx)

    const canvas = ctx.el.querySelector('canvas')
    expect(canvas.getAttribute('aria-label')).toBe('Bar chart')
  })

  it('registers a handleEvent listener for chart-data', () => {
    const ctx = createMockHookContext()
    BarChart.mounted.call(ctx)

    expect(ctx.handleEvent).toHaveBeenCalledTimes(1)
    expect(ctx.handleEvent).toHaveBeenCalledWith(
      'chart-data:test-bar-chart',
      expect.any(Function)
    )
  })

  it('creates a Chart instance with type "bar" on mount', async () => {
    const { default: Chart } = await import('chart.js/auto')
    const ctx = createMockHookContext()
    BarChart.mounted.call(ctx)

    expect(Chart).toHaveBeenCalled()
    const callArgs = Chart.mock.calls[Chart.mock.calls.length - 1][1]
    expect(callArgs.type).toBe('bar')
    expect(callArgs.options.indexAxis).toBe('y')
  })

  it('updates chart data when handleEvent callback is invoked', () => {
    const ctx = createMockHookContext()
    BarChart.mounted.call(ctx)

    const callback = ctx.handleEvent.mock.calls[0][1]
    callback({ labels: ['cat', 'dog', 'bird'], values: [0.9, 0.7, 0.3] })

    expect(ctx.chart.data.labels).toEqual(['cat', 'dog', 'bird'])
    expect(ctx.chart.data.datasets[0].data).toEqual([0.9, 0.7, 0.3])
    expect(ctx.chart.update).toHaveBeenCalledTimes(1)
  })

  it('destroys chart on destroyed lifecycle', () => {
    const ctx = createMockHookContext()
    BarChart.mounted.call(ctx)

    const destroySpy = ctx.chart.destroy
    BarChart.destroyed.call(ctx)

    expect(destroySpy).toHaveBeenCalledTimes(1)
  })

  it('does not throw on destroyed when no chart exists', () => {
    const ctx = { chart: null }
    expect(() => BarChart.destroyed.call(ctx)).not.toThrow()
  })
})
