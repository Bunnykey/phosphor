import Chart from "chart.js/auto"

const BarChart = {
  mounted() {
    const canvas = this.el.querySelector("canvas")
    canvas.setAttribute("role", "img")
    canvas.setAttribute("aria-label", this.el.dataset.ariaLabel || this.el.getAttribute("aria-label") || "Bar chart")

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
          x: {
            beginAtZero: true,
            max: 1.0,
            ticks: { color: '#9ca3af' },
            grid: { color: 'rgba(75, 85, 99, 0.3)' },
          },
          y: {
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

    this.handleEvent("chart-data:" + this.el.id, ({ labels, values }) => {
      this.chart.data.labels = labels
      this.chart.data.datasets[0].data = values
      this.chart.update()
    })
  },

  destroyed() {
    if (this.chart) this.chart.destroy()
  },
}

export default BarChart
