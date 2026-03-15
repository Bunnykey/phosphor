import { describe, it, expect, vi, beforeEach } from 'vitest'
import { setupChartMock, createMockHookContext } from './test_helpers'

setupChartMock()

import LineChart from '../line_chart'

describe('LineChart hook', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('has a mounted method', () => {
    expect(typeof LineChart.mounted).toBe('function')
  })

  it('has a destroyed method', () => {
    expect(typeof LineChart.destroyed).toBe('function')
  })

  it('sets role="img" on the canvas after mount', () => {
    const ctx = createMockHookContext('test-line-chart', 'Test line chart')
    LineChart.mounted.call(ctx)

    const canvas = ctx.el.querySelector('canvas')
    expect(canvas.getAttribute('role')).toBe('img')
  })

  it('sets aria-label on the canvas from dataset after mount', () => {
    const ctx = createMockHookContext('test-line-chart', 'Test line chart')
    LineChart.mounted.call(ctx)

    const canvas = ctx.el.querySelector('canvas')
    expect(canvas.getAttribute('aria-label')).toBe('Test line chart')
  })

  it('falls back to default aria-label when none provided', () => {
    const ctx = createMockHookContext('test-line-chart', 'Test line chart')
    delete ctx.el.dataset.ariaLabel
    LineChart.mounted.call(ctx)

    const canvas = ctx.el.querySelector('canvas')
    expect(canvas.getAttribute('aria-label')).toBe('Line chart')
  })

  it('registers a handleEvent listener for chart-data', () => {
    const ctx = createMockHookContext('test-line-chart', 'Test line chart')
    LineChart.mounted.call(ctx)

    expect(ctx.handleEvent).toHaveBeenCalledTimes(1)
    expect(ctx.handleEvent).toHaveBeenCalledWith(
      'chart-data:test-line-chart',
      expect.any(Function)
    )
  })

  it('creates a Chart instance on mount', async () => {
    const { default: Chart } = await import('chart.js/auto')
    const ctx = createMockHookContext('test-line-chart', 'Test line chart')
    LineChart.mounted.call(ctx)

    expect(Chart).toHaveBeenCalledTimes(1)
    const callArgs = Chart.mock.calls[0][1]
    expect(callArgs.type).toBe('line')
  })

  it('updates chart data when handleEvent callback is invoked', () => {
    const ctx = createMockHookContext('test-line-chart', 'Test line chart')
    LineChart.mounted.call(ctx)

    const callback = ctx.handleEvent.mock.calls[0][1]
    callback({ labels: ['a', 'b'], values: [1, 2], anomalies: null })

    expect(ctx.chart.data.labels).toEqual(['a', 'b'])
    expect(ctx.chart.data.datasets[0].data).toEqual([1, 2])
    expect(ctx.chart.update).toHaveBeenCalledWith('none')
  })

  it('handles multi-dataset values (array of arrays)', () => {
    const ctx = createMockHookContext('test-line-chart', 'Test line chart')
    ctx.chart = null
    LineChart.mounted.call(ctx)

    // Ensure there are two datasets for the test
    ctx.chart.data.datasets = [{ data: [] }, { data: [] }]

    const callback = ctx.handleEvent.mock.calls[0][1]
    callback({ labels: ['x', 'y'], values: [[10, 20], [30, 40]], anomalies: null })

    expect(ctx.chart.data.datasets[0].data).toEqual([10, 20])
    expect(ctx.chart.data.datasets[1].data).toEqual([30, 40])
  })

  it('destroys chart on destroyed lifecycle', () => {
    const ctx = createMockHookContext('test-line-chart', 'Test line chart')
    LineChart.mounted.call(ctx)

    const destroySpy = ctx.chart.destroy
    LineChart.destroyed.call(ctx)

    expect(destroySpy).toHaveBeenCalledTimes(1)
  })

  it('does not throw on destroyed when no chart exists', () => {
    const ctx = { chart: null }
    expect(() => LineChart.destroyed.call(ctx)).not.toThrow()
  })
})
