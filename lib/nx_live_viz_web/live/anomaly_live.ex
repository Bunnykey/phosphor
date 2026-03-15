defmodule NxLiveVizWeb.AnomalyLive do
  use NxLiveVizWeb, :live_view

  alias NxLiveViz.ML.AnomalyDetector

  @window_size 20
  @max_points 200

  @seed_count 30
  @anomaly_indices [7, 15, 22, 28]

  @source_map %{
    "sine" => :sine,
    "ecg" => :ecg,
    "network" => :network,
    "crypto" => :crypto,
    "system" => :system
  }

  @source_labels %{
    sine: "Sine Wave",
    ecg: "ECG Heartbeat",
    network: "Network Traffic",
    crypto: "Crypto API (BTC)",
    system: "System Metrics"
  }

  @impl true
  def mount(_params, _session, socket) do
    detector =
      if connected?(socket) do
        AnomalyDetector.cached_detector(input_size: @window_size)
      else
        nil
      end

    socket =
      assign(socket,
        data_points: [],
        anomalies: [],
        detector: detector,
        streaming: false,
        source: :sine,
        source_label: @source_labels[:sine],
        window_size: @window_size,
        max_points: @max_points,
        anomaly_count: 0
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("start", _params, %{assigns: %{streaming: true}} = socket) do
    {:noreply, socket}
  end

  def handle_event("start", _params, socket) do
    Phoenix.PubSub.subscribe(NxLiveViz.PubSub, "sensor:data")
    NxLiveViz.set_data_source(socket.assigns.source)

    # Push seed data for immediate visual feedback
    seed = seed_data()
    points = seed |> Enum.map(& &1.value) |> Enum.reverse()
    anomalies = seed |> Enum.map(& &1.anomaly) |> Enum.reverse()
    count = Enum.count(seed, & &1.anomaly)

    display_points = Enum.reverse(points)
    display_anomalies = Enum.reverse(anomalies)
    labels = chart_labels(display_points)

    socket =
      socket
      |> assign(
        streaming: true,
        data_points: points,
        anomalies: anomalies,
        anomaly_count: count
      )
      |> push_event("chart-data:anomaly-chart", %{
        labels: labels,
        values: display_points,
        anomalies: display_anomalies
      })

    {:noreply, socket}
  end

  def handle_event("stop", _params, socket) do
    Phoenix.PubSub.unsubscribe(NxLiveViz.PubSub, "sensor:data")
    NxLiveViz.Data.CryptoAPI.deactivate()
    NxLiveViz.Data.SystemMetrics.deactivate()

    {:noreply, assign(socket, streaming: false)}
  end

  def handle_event("change-source", %{"source" => source}, socket) do
    case Map.fetch(@source_map, source) do
      {:ok, source_atom} ->
        if socket.assigns.streaming do
          NxLiveViz.set_data_source(source_atom)
        end

        {:noreply,
         assign(socket,
           source: source_atom,
           source_label: @source_labels[source_atom],
           data_points: [],
           anomalies: [],
           anomaly_count: 0
         )}

      :error ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:sensor_data, _point}, %{assigns: %{streaming: false}} = socket) do
    {:noreply, socket}
  end

  def handle_info({:sensor_data, point}, socket) do
    points = [point.value | socket.assigns.data_points] |> Enum.take(@max_points)
    anomalies = [point.anomaly | socket.assigns.anomalies] |> Enum.take(@max_points)

    detection_result =
      if length(points) >= @window_size and socket.assigns.detector do
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
    labels = chart_labels(display_points)

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

  defp seed_data do
    now = DateTime.utc_now()

    Enum.map(0..(@seed_count - 1), fn i ->
      is_anomaly = i in @anomaly_indices

      base_value = NxLiveViz.Data.Simulator.normal_value(i)

      value =
        if is_anomaly do
          offset = if rem(i, 2) == 0, do: 20.0, else: -20.0
          base_value + offset
        else
          base_value
        end

      ms_offset = (@seed_count - 1 - i) * 100
      timestamp = DateTime.add(now, -ms_offset, :millisecond)

      %{value: value, timestamp: timestamp, anomaly: is_anomaly}
    end)
  end

  defp chart_labels([]), do: []
  defp chart_labels(list), do: Enum.map(1..length(list), &to_string/1)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-xl font-semibold">Anomaly Detection</h2>
          <p class="text-sm text-gray-500 dark:text-gray-400">Autoencoder-based real-time anomaly detection</p>
        </div>
        <div class="flex items-center gap-3">
          <span class="text-sm text-red-600 dark:text-red-400">
            Anomalies: {@anomaly_count}
          </span>
          <select
            name="source"
            phx-change="change-source"
            value={to_string(@source)}
            class="bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-700 rounded px-3 py-1 text-sm text-gray-900 dark:text-gray-100"
          >
            <option value="sine">Sine Wave</option>
            <option value="ecg">ECG Heartbeat</option>
            <option value="network">Network Traffic</option>
            <option value="crypto">Crypto API (BTC)</option>
            <option value="system">System Metrics</option>
          </select>
          <button
            :if={!@streaming}
            phx-click="start"
            class="px-4 py-1.5 bg-green-600 hover:bg-green-700 rounded-lg text-sm font-medium text-white"
          >
            Start
          </button>
          <button
            :if={@streaming}
            phx-click="stop"
            class="px-4 py-1.5 bg-red-600 hover:bg-red-700 rounded-lg text-sm font-medium text-white"
          >
            Stop
          </button>
        </div>
      </div>

      <div class="flex flex-wrap items-center gap-2 text-xs">
        <span class="px-2 py-1 rounded-full bg-indigo-100 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-300 font-medium">
          {@source_label}
        </span>
        <span class="px-2 py-1 rounded-full bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400">
          Window: {@window_size}
        </span>
        <span class="px-2 py-1 rounded-full bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400">
          Threshold: 0.5
        </span>
        <span class="px-2 py-1 rounded-full bg-gray-100 dark:bg-gray-800 text-gray-600 dark:text-gray-400">
          Max: {@max_points}
        </span>
        <span :if={@streaming} class="inline-flex items-center gap-1 px-2 py-1 rounded-full bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400">
          <span class="w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse"></span>
          Live
        </span>
      </div>

      <div id="anomaly-chart" phx-hook="LineChart" phx-update="ignore" data-max-points="200" data-x-label="Time" data-y-label="Signal Value" class="bg-gray-100 dark:bg-gray-900 rounded-lg p-4 h-80">
        <canvas></canvas>
      </div>
    </div>
    """
  end
end
