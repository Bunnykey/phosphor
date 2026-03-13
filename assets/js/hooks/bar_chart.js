import Chart from "chart.js/auto"

const BarChart = {
  mounted() {
    const ctx = this.el.querySelector("canvas").getContext("2d")
    this.chart = new Chart(ctx, {
      type: "bar",
      data: {
        labels: [],
        datasets: [{
          label: this.el.dataset.label || "Score",
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
          x: { beginAtZero: true, max: 1.0 },
        },
        plugins: {
          legend: { display: false },
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
