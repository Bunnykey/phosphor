import { describe, it, expect, vi, beforeEach } from 'vitest'
import { setupChartMock, createMockHookContext } from './test_helpers'

setupChartMock()

import HistogramChart from '../histogram_chart'

describe('HistogramChart hook', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('has a mounted method', () => {
    expect(typeof HistogramChart.mounted).toBe('function')
  })

  it('has a destroyed method', () => {
    expect(typeof HistogramChart.destroyed).toBe('function')
  })

  it('sets role="img" on the canvas after mount', () => {
    const ctx = createMockHookContext('test-histogram-chart', 'Test histogram chart')
    HistogramChart.mounted.call(ctx)

    const canvas = ctx.el.querySelector('canvas')
    expect(canvas.getAttribute('role')).toBe('img')
  })

  it('sets aria-label on the canvas from dataset after mount', () => {
    const ctx = createMockHookContext('test-histogram-chart', 'Test histogram chart')
    HistogramChart.mounted.call(ctx)

    const canvas = ctx.el.querySelector('canvas')
    expect(canvas.getAttribute('aria-label')).toBe('Test histogram chart')
  })

  it('falls back to default aria-label when none provided', () => {
    const ctx = createMockHookContext('test-histogram-chart', 'Test histogram chart')
    delete ctx.el.dataset.ariaLabel
    HistogramChart.mounted.call(ctx)

    const canvas = ctx.el.querySelector('canvas')
    expect(canvas.getAttribute('aria-label')).toBe('Histogram chart showing weight distribution')
  })

  it('registers a handleEvent listener for chart-data', () => {
    const ctx = createMockHookContext('test-histogram-chart', 'Test histogram chart')
    HistogramChart.mounted.call(ctx)

    expect(ctx.handleEvent).toHaveBeenCalledTimes(1)
    expect(ctx.handleEvent).toHaveBeenCalledWith(
      'chart-data:test-histogram-chart',
      expect.any(Function)
    )
  })

  it('creates a Chart instance with type "bar" on mount', async () => {
    const { default: Chart } = await import('chart.js/auto')
    const ctx = createMockHookContext('test-histogram-chart', 'Test histogram chart')
    HistogramChart.mounted.call(ctx)

    expect(Chart).toHaveBeenCalled()
    const callArgs = Chart.mock.calls[Chart.mock.calls.length - 1][1]
    expect(callArgs.type).toBe('bar')
    // Histogram uses default (vertical) axis, unlike BarChart which uses indexAxis: 'y'
    expect(callArgs.options.indexAxis).toBeUndefined()
  })

  it('updates chart data when handleEvent callback is invoked with bins and counts', () => {
    const ctx = createMockHookContext('test-histogram-chart', 'Test histogram chart')
    HistogramChart.mounted.call(ctx)

    const callback = ctx.handleEvent.mock.calls[0][1]
    callback({ bins: ['0-10', '10-20', '20-30'], counts: [5, 12, 3] })

    expect(ctx.chart.data.labels).toEqual(['0-10', '10-20', '20-30'])
    expect(ctx.chart.data.datasets[0].data).toEqual([5, 12, 3])
    expect(ctx.chart.update).toHaveBeenCalledWith('none')
  })

  it('destroys chart on destroyed lifecycle', () => {
    const ctx = createMockHookContext('test-histogram-chart', 'Test histogram chart')
    HistogramChart.mounted.call(ctx)

    const destroySpy = ctx.chart.destroy
    HistogramChart.destroyed.call(ctx)

    expect(destroySpy).toHaveBeenCalledTimes(1)
  })

  it('does not throw on destroyed when no chart exists', () => {
    const ctx = { chart: null }
    expect(() => HistogramChart.destroyed.call(ctx)).not.toThrow()
  })
})
