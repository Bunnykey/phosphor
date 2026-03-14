defmodule NxLiveVizWeb.AnomalyLive do
  use NxLiveVizWeb, :live_view

  alias NxLiveViz.ML.AnomalyDetector

  @window_size 20
  @max_points 200

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(NxLiveViz.PubSub, "sensor:data")
    end

    detector = AnomalyDetector.init_params(input_size: @window_size)

    {:ok,
     assign(socket,
       data_points: [],
       anomalies: [],
       detector: detector,
       source: :simulator,
       anomaly_count: 0
     )}
  end

  @impl true
  def handle_info({:sensor_data, point}, socket) do
    points = [point.value | socket.assigns.data_points] |> Enum.take(@max_points)
    anomalies = [point.anomaly | socket.assigns.anomalies] |> Enum.take(@max_points)

    # Run detection when we have enough data
    detection_result =
      if length(points) >= @window_size do
        window =
          Enum.take(points, @window_size)
          |> Nx.tensor()
          |> Nx.reshape({1, @window_size})

        AnomalyDetector.predict(socket.assigns.detector, window)
      else
        nil
      end

    anomaly_count =
      if detection_result && detection_result.is_anomaly,
        do: socket.assigns.anomaly_count + 1,
        else: socket.assigns.anomaly_count

    display_points = Enum.reverse(points)
    display_anomalies = Enum.reverse(anomalies)
    labels = Enum.map(1..length(display_points), &to_string/1)

    socket =
      socket
      |> assign(data_points: points, anomalies: anomalies, anomaly_count: anomaly_count)
      |> push_event("chart-data:anomaly-chart", %{
        labels: labels,
        values: display_points,
        anomalies: display_anomalies
      })

    {:noreply, socket}
  end

  @impl true
  def handle_event("change-source", %{"source" => "crypto"}, socket) do
    NxLiveViz.Data.CryptoAPI.activate()
    {:noreply, assign(socket, source: :crypto, data_points: [], anomalies: [], anomaly_count: 0)}
  end

  def handle_event("change-source", %{"source" => "simulator"}, socket) do
    NxLiveViz.Data.CryptoAPI.deactivate()
    {:noreply, assign(socket, source: :simulator, data_points: [], anomalies: [], anomaly_count: 0)}
  end

  def handle_event("change-source", %{"source" => _source}, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-xl font-semibold">Anomaly Detection</h2>
          <p class="text-sm text-gray-400">Autoencoder-based real-time anomaly detection</p>
        </div>
        <div class="flex items-center gap-4">
          <span class="text-sm text-red-400">
            Anomalies detected: {@anomaly_count}
          </span>
          <select
            phx-change="change-source"
            name="source"
            class="bg-gray-800 border border-gray-700 rounded px-3 py-1 text-sm"
          >
            <option value="simulator" selected={@source == :simulator}>Simulator</option>
            <option value="crypto" selected={@source == :crypto}>Crypto API</option>
            <option value="system" selected={@source == :system}>System Metrics</option>
          </select>
        </div>
      </div>

      <div id="anomaly-chart" phx-hook="LineChart" class="bg-gray-900 rounded-lg p-4 h-80">
        <canvas></canvas>
      </div>
    </div>
    """
  end
end
