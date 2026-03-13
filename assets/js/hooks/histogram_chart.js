import Chart from "chart.js/auto"

const HistogramChart = {
  mounted() {
    const ctx = this.el.querySelector("canvas").getContext("2d")
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
          x: { display: true, title: { display: true, text: "Value" } },
          y: { display: true, title: { display: true, text: "Frequency" }, beginAtZero: true },
        },
        plugins: {
          legend: { display: false },
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
