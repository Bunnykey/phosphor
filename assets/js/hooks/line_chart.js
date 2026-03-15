import Chart from "chart.js/auto"
import { setupCanvas, legendConfig, axisConfig, chartEventName, destroyChart } from "./chart_utils"

// Plugin to draw vertical dashed lines at epoch boundaries
const epochBoundaryPlugin = {
  id: "epochBoundary",
  afterDraw(chart) {
    const boundaries = chart.config._epochBoundaries
    if (!boundaries || boundaries.length === 0) return
    const { ctx, chartArea: { top, bottom }, scales: { x } } = chart
    ctx.save()
    ctx.strokeStyle = "rgba(156, 163, 175, 0.5)"
    ctx.lineWidth = 1
    ctx.setLineDash([4, 4])
    for (const idx of boundaries) {
      const xPos = x.getPixelForValue(idx)
      if (xPos >= x.left && xPos <= x.right) {
        ctx.beginPath()
        ctx.moveTo(xPos, top)
        ctx.lineTo(xPos, bottom)
        ctx.stroke()
      }
    }
    ctx.restore()
  },
}

const LineChart = {
  mounted() {
    const canvas = setupCanvas(this.el, "Line chart")

    const ctx = canvas.getContext("2d")
    this.chart = new Chart(ctx, {
      type: "line",
      data: {
        labels: [],
        datasets: this.el.dataset.datasets
          ? JSON.parse(this.el.dataset.datasets)
          : [{
              label: this.el.dataset.label || "Value",
              data: [],
              borderColor: "rgb(99, 102, 241)",
              backgroundColor: "rgba(99, 102, 241, 0.1)",
              fill: true,
              tension: 0.3,
              pointRadius: 0,
            }],
      },
      plugins: [epochBoundaryPlugin],
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 0 },
        scales: {
          x: axisConfig({
            display: true,
            title: this.el.dataset.xLabel ? {
              display: true,
              text: this.el.dataset.xLabel,
              color: '#9ca3af',
              font: { size: 11 },
            } : { display: false },
          }),
          y: axisConfig({
            display: true,
            beginAtZero: false,
            title: this.el.dataset.yLabel ? {
              display: true,
              text: this.el.dataset.yLabel,
              color: '#9ca3af',
              font: { size: 11 },
            } : { display: false },
          }),
        },
        plugins: {
          legend: legendConfig(),
          tooltip: {
            enabled: true,
            callbacks: {
              label: (ctx) => {
                const ds = ctx.dataset
                const isAnomaly = Array.isArray(ds.pointRadius) && ds.pointRadius[ctx.dataIndex] > 0
                const val = typeof ctx.parsed.y === "number" ? ctx.parsed.y.toFixed(2) : ctx.parsed.y
                return isAnomaly ? `⚠ ANOMALY: ${val}` : `${ds.label || "Value"}: ${val}`
              }
            }
          },
        },
      },
    })

    // Track epoch boundaries for vertical line drawing
    this.epochBoundaries = []

    this.handleEvent(chartEventName(this.el), ({ labels, values, anomalies, epoch_boundary }) => {
      this.chart.data.labels = labels
      if (Array.isArray(values[0])) {
        values.forEach((v, i) => {
          this.chart.data.datasets[i].data = v
        })
      } else {
        this.chart.data.datasets[0].data = values
      }

      if (anomalies) {
        this.chart.data.datasets[0].pointRadius = anomalies.map(a => a ? 6 : 0)
        this.chart.data.datasets[0].pointBackgroundColor = anomalies.map(a =>
          a ? "rgb(239, 68, 68)" : "rgb(99, 102, 241)"
        )
      }

      if (epoch_boundary != null && !this.epochBoundaries.includes(epoch_boundary)) {
        this.epochBoundaries.push(epoch_boundary)
      }
      if (this.chart.config) {
        this.chart.config._epochBoundaries = this.epochBoundaries
      }

      this.chart.update("none")
    })

    // Incremental append: push a single point instead of replacing all data
    this.handleEvent("chart-append:" + this.el.id, ({ label, value, anomaly }) => {
      const maxPoints = parseInt(this.el.dataset.maxPoints) || 200
      this.chart.data.labels.push(label)
      this.chart.data.datasets[0].data.push(value)

      if (anomaly !== undefined) {
        if (!Array.isArray(this.chart.data.datasets[0].pointRadius)) {
          this.chart.data.datasets[0].pointRadius = []
          this.chart.data.datasets[0].pointBackgroundColor = []
        }
        this.chart.data.datasets[0].pointRadius.push(anomaly ? 6 : 0)
        this.chart.data.datasets[0].pointBackgroundColor.push(
          anomaly ? "rgb(239, 68, 68)" : "rgb(99, 102, 241)"
        )
      }

      while (this.chart.data.labels.length > maxPoints) {
        this.chart.data.labels.shift()
        this.chart.data.datasets[0].data.shift()
        if (Array.isArray(this.chart.data.datasets[0].pointRadius)) {
          this.chart.data.datasets[0].pointRadius.shift()
          this.chart.data.datasets[0].pointBackgroundColor.shift()
        }
      }

      this.chart.update("none")
    })
  },

  destroyed() {
    destroyChart(this)
  },
}

export default LineChart
