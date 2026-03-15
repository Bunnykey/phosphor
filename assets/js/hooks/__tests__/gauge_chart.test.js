import { describe, it, expect, vi, beforeEach } from 'vitest'
import { setupChartMock, createMockHookContext } from './test_helpers'

setupChartMock()

import GaugeChart from '../gauge_chart'

describe('GaugeChart hook', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('has a mounted method', () => {
    expect(typeof GaugeChart.mounted).toBe('function')
  })

  it('has a destroyed method', () => {
    expect(typeof GaugeChart.destroyed).toBe('function')
  })

  it('sets role="img" on the canvas after mount', () => {
    const ctx = createMockHookContext('test-gauge-chart', 'Test gauge chart')
    GaugeChart.mounted.call(ctx)

    const canvas = ctx.el.querySelector('canvas')
    expect(canvas.getAttribute('role')).toBe('img')
  })

  it('sets aria-label on the canvas from dataset after mount', () => {
    const ctx = createMockHookContext('test-gauge-chart', 'Test gauge chart')
    GaugeChart.mounted.call(ctx)

    const canvas = ctx.el.querySelector('canvas')
    expect(canvas.getAttribute('aria-label')).toBe('Test gauge chart')
  })

  it('falls back to default aria-label when none provided', () => {
    const ctx = createMockHookContext('test-gauge-chart', 'Test gauge chart')
    delete ctx.el.dataset.ariaLabel
    GaugeChart.mounted.call(ctx)

    const canvas = ctx.el.querySelector('canvas')
    expect(canvas.getAttribute('aria-label')).toBe('Gauge chart showing sentiment distribution')
  })

  it('registers a handleEvent listener for chart-data', () => {
    const ctx = createMockHookContext('test-gauge-chart', 'Test gauge chart')
    GaugeChart.mounted.call(ctx)

    expect(ctx.handleEvent).toHaveBeenCalledTimes(1)
    expect(ctx.handleEvent).toHaveBeenCalledWith(
      'chart-data:test-gauge-chart',
      expect.any(Function)
    )
  })

  it('creates a Chart instance with type "doughnut" on mount', async () => {
    const { default: Chart } = await import('chart.js/auto')
    const ctx = createMockHookContext('test-gauge-chart', 'Test gauge chart')
    GaugeChart.mounted.call(ctx)

    expect(Chart).toHaveBeenCalled()
    const callArgs = Chart.mock.calls[Chart.mock.calls.length - 1][1]
    expect(callArgs.type).toBe('doughnut')
    expect(callArgs.options.rotation).toBe(-90)
    expect(callArgs.options.circumference).toBe(180)
  })

  it('updates chart data when handleEvent callback is invoked', () => {
    const ctx = createMockHookContext('test-gauge-chart', 'Test gauge chart')
    GaugeChart.mounted.call(ctx)

    const callback = ctx.handleEvent.mock.calls[0][1]
    callback({ positive: 0.75, negative: 0.15, neutral: 0.10 })

    expect(ctx.chart.data.datasets[0].data).toEqual([
      '75.0', '15.0', '10.0'
    ])
    expect(ctx.chart.update).toHaveBeenCalledTimes(1)
  })

  it('destroys chart on destroyed lifecycle', () => {
    const ctx = createMockHookContext('test-gauge-chart', 'Test gauge chart')
    GaugeChart.mounted.call(ctx)

    const destroySpy = ctx.chart.destroy
    GaugeChart.destroyed.call(ctx)

    expect(destroySpy).toHaveBeenCalledTimes(1)
  })

  it('does not throw on destroyed when no chart exists', () => {
    const ctx = { chart: null }
    expect(() => GaugeChart.destroyed.call(ctx)).not.toThrow()
  })
})
