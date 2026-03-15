import Chart from "chart.js/auto"
import { setupCanvas, legendConfig, axisConfig, chartEventName, destroyChart, CHART_TEXT_COLOR } from "./chart_utils"

const HistogramChart = {
  mounted() {
    const canvas = setupCanvas(this.el, "Histogram chart showing weight distribution")

    const ctx = canvas.getContext("2d")
    this.chart = new Chart(ctx, {
      type: "bar",
      data: {
        labels: [],
        datasets: [{
          label: "Weight Distribution",
          data: [],
          backgroundColor: "rgba(99, 102, 241, 0.6)",
          borderColor: "rgba(99, 102, 241, 1)",
          borderWidth: 1,
        }],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 0 },
        scales: {
          x: axisConfig({
            display: true,
            title: { display: true, text: "Value", color: CHART_TEXT_COLOR },
          }),
          y: axisConfig({
            display: true,
            title: { display: true, text: "Frequency", color: CHART_TEXT_COLOR },
            beginAtZero: true,
          }),
        },
        plugins: {
          legend: legendConfig(),
        },
      },
    })

    this.handleEvent(chartEventName(this.el), ({ bins, counts }) => {
      this.chart.data.labels = bins
      this.chart.data.datasets[0].data = counts
      this.chart.update("none")
    })
  },

  destroyed() {
    destroyChart(this)
  },
}

export default HistogramChart
