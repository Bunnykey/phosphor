// Shared chart theme constants and utilities

export const CHART_TEXT_COLOR = '#9ca3af'
export const CHART_GRID_COLOR = 'rgba(75, 85, 99, 0.3)'

export const legendConfig = (position = 'top') => ({
  display: true,
  position,
  labels: {
    color: CHART_TEXT_COLOR,
    font: { size: 11 },
    boxWidth: 12,
    padding: 8,
  },
})

export const axisConfig = (extra = {}) => ({
  ticks: { color: CHART_TEXT_COLOR },
  grid: { color: CHART_GRID_COLOR },
  ...extra,
})

export function setupCanvas(el, defaultLabel) {
  const canvas = el.querySelector("canvas")
  canvas.setAttribute("role", "img")
  canvas.setAttribute("aria-label",
    el.dataset.ariaLabel || el.getAttribute("aria-label") || defaultLabel)
  return canvas
}

export function chartEventName(el) {
  return "chart-data:" + el.id
}

export function destroyChart(hook) {
  if (hook.chart) hook.chart.destroy()
}
