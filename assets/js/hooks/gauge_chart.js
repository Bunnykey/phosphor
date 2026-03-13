import Chart from "chart.js/auto"

const GaugeChart = {
  mounted() {
    const ctx = this.el.querySelector("canvas").getContext("2d")
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
          legend: { display: true, position: "bottom" },
        },
      },
    })

    this.handleEvent("chart-data:" + this.el.id, ({ positive, negative, neutral }) => {
      this.chart.data.datasets[0].data = [
        (positive * 100).toFixed(1),
        (negative * 100).toFixed(1),
        (neutral * 100).toFixed(1),
      ]
      this.chart.update()
    })
  },

  destroyed() {
    if (this.chart) this.chart.destroy()
  },
}

export default GaugeChart
