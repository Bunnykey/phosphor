import Chart from "chart.js/auto"
import { setupCanvas, legendConfig, axisConfig, chartEventName, destroyChart } from "./chart_utils"

const BarChart = {
  mounted() {
    const canvas = setupCanvas(this.el, "Bar chart")

    const ctx = canvas.getContext("2d")
    this.chart = new Chart(ctx, {
      type: "bar",
      data: {
        labels: [],
        datasets: [{
          label: this.el.dataset.label || "Top-5 Predictions",
          data: [],
          backgroundColor: [
            "rgba(99, 102, 241, 0.8)",
            "rgba(139, 92, 246, 0.8)",
            "rgba(168, 85, 247, 0.8)",
            "rgba(192, 132, 252, 0.8)",
            "rgba(216, 180, 254, 0.8)",
          ],
          borderRadius: 4,
        }],
      },
      options: {
        indexAxis: "y",
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 300 },
        scales: {
          x: axisConfig({ beginAtZero: true, max: 1.0, title: { display: true, text: "Confidence", color: '#9ca3af', font: { size: 11 } } }),
          y: axisConfig({ title: { display: true, text: "Class", color: '#9ca3af', font: { size: 11 } } }),
        },
        plugins: {
          legend: legendConfig(),
        },
      },
    })

    this.handleEvent(chartEventName(this.el), ({ labels, values }) => {
      this.chart.data.labels = labels
      this.chart.data.datasets[0].data = values
      this.chart.update()
    })
  },

  destroyed() {
    destroyChart(this)
  },
}

export default BarChart
