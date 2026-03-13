import Chart from "chart.js/auto"

const LineChart = {
  mounted() {
    const ctx = this.el.querySelector("canvas").getContext("2d")
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
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: { duration: 0 },
        scales: {
          x: { display: true },
          y: { display: true, beginAtZero: false },
        },
        plugins: {
          legend: { display: true },
        },
      },
    })

    this.handleEvent("chart-data:" + this.el.id, ({ labels, values, anomalies }) => {
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

      this.chart.update("none")
    })
  },

  destroyed() {
    if (this.chart) this.chart.destroy()
  },
}

export default LineChart
