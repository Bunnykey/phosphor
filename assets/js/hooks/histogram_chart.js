import Chart from "chart.js/auto"

const HistogramChart = {
  mounted() {
    const canvas = this.el.querySelector("canvas")
    canvas.setAttribute("role", "img")
    canvas.setAttribute("aria-label", this.el.dataset.ariaLabel || this.el.getAttribute("aria-label") || "Histogram chart showing weight distribution")

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
          x: {
            display: true,
            title: { display: true, text: "Value", color: '#9ca3af' },
            ticks: { color: '#9ca3af' },
            grid: { color: 'rgba(75, 85, 99, 0.3)' },
          },
          y: {
            display: true,
            title: { display: true, text: "Frequency", color: '#9ca3af' },
            beginAtZero: true,
            ticks: { color: '#9ca3af' },
            grid: { color: 'rgba(75, 85, 99, 0.3)' },
          },
        },
        plugins: {
          legend: {
            display: true,
            position: 'top',
            labels: {
              color: '#9ca3af',
              font: { size: 11 },
              boxWidth: 12,
              padding: 8,
            },
          },
        },
      },
    })

    this.handleEvent("chart-data:" + this.el.id, ({ bins, counts }) => {
      this.chart.data.labels = bins
      this.chart.data.datasets[0].data = counts
      this.chart.update("none")
    })
  },

  destroyed() {
    if (this.chart) this.chart.destroy()
  },
}

export default HistogramChart
