import { describe, it, expect, vi } from 'vitest'
import { setupChartMock } from './test_helpers'

// Mock chart.js/auto so the hooks can be imported without a real Canvas
setupChartMock()

import Hooks from '../index'

describe('Hooks index', () => {
  it('exports LineChart', () => {
    expect(Hooks.LineChart).toBeDefined()
  })

  it('exports BarChart', () => {
    expect(Hooks.BarChart).toBeDefined()
  })

  it('exports GaugeChart', () => {
    expect(Hooks.GaugeChart).toBeDefined()
  })

  it('exports HistogramChart', () => {
    expect(Hooks.HistogramChart).toBeDefined()
  })

  it('LineChart has a mounted method', () => {
    expect(typeof Hooks.LineChart.mounted).toBe('function')
  })

  it('BarChart has a mounted method', () => {
    expect(typeof Hooks.BarChart.mounted).toBe('function')
  })

  it('GaugeChart has a mounted method', () => {
    expect(typeof Hooks.GaugeChart.mounted).toBe('function')
  })

  it('HistogramChart has a mounted method', () => {
    expect(typeof Hooks.HistogramChart.mounted).toBe('function')
  })

  it('exports exactly 4 hooks', () => {
    expect(Object.keys(Hooks)).toHaveLength(4)
  })
})
