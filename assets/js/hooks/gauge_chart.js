import Chart from "chart.js/auto"
import { setupCanvas, legendConfig, chartEventName, destroyChart } from "./chart_utils"

const GaugeChart = {
  mounted() {
    const canvas = setupCanvas(this.el, "Gauge chart showing sentiment distribution")

    const ctx = canvas.getContext("2d")
    this.chart = new Chart(ctx, {
      type: "doughnut",
      data: {
        labels: ["Positive", "Negative", "Neutral"],
        datasets: [{
          data: [0, 0, 100],
          backgroundColor: [
            "rgba(34, 197, 94, 0.8)",
            "rgba(239, 68, 68, 0.8)",
            "rgba(156, 163, 175, 0.4)",
          ],
          borderWidth: 0,
        }],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        rotation: -90,
        circumference: 180,
        cutout: "75%",
        plugins: {
          legend: legendConfig('bottom'),
        },
      },
    })

    this.handleEvent(chartEventName(this.el), ({ positive, negative, neutral }) => {
      this.chart.data.datasets[0].data = [
        (positive * 100).toFixed(1),
        (negative * 100).toFixed(1),
        (neutral * 100).toFixed(1),
      ]
      this.chart.update()
    })
  },

  destroyed() {
    destroyChart(this)
  },
}

export default GaugeChart
