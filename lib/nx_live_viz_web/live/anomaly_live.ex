defmodule NxLiveVizWeb.AnomalyLive do
  use NxLiveVizWeb, :live_view

  alias NxLiveViz.ML.AnomalyDetector

  @max_points 200

  @source_map %{
    "sine" => :sine,
    "ecg" => :ecg,
    "network" => :network,
    "crypto" => :crypto,
    "system" => :system
  }

  @sources [
    {"sine", "Sine Wave"},
    {"ecg", "ECG Heartbeat"},
    {"network", "Network Traffic"},
    {"crypto", "Crypto API (BTC)"},
    {"system", "System Metrics"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    window_size = 20
    threshold = 0.5

    detector =
      if connected?(socket) do
        AnomalyDetector.cached_detector(input_size: window_size)
      else
        nil
      end

    socket =
      assign(socket,
        current_path: "/anomaly",
        data_points: [],
        anomalies: [],
        detector: detector,
        streaming: false,
        source: :sine,
        sources: @sources,
        window_size: window_size,
        threshold: threshold,
        max_points: @max_points,
        anomaly_count: 0
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("update-params", params, socket) do
    source_key = Map.get(params, "source", to_string(socket.assigns.source))
    window = safe_int(params["window"], socket.assigns.window_size) |> max(5) |> min(50)
    threshold = safe_float(params["threshold"], socket.assigns.threshold) |> max(0.1) |> min(2.0)

    source = Map.get(@source_map, source_key, socket.assigns.source)

    {:noreply, assign(socket, source: source, window_size: window, threshold: threshold)}
  end

  def handle_event("start", _params, %{assigns: %{streaming: true}} = socket) do
    {:noreply, socket}
  end

  def handle_event("start", _params, socket) do
    Phoenix.PubSub.subscribe(NxLiveViz.PubSub, "sensor:data")
    NxLiveViz.set_data_source(socket.assigns.source)

    {:noreply,
     assign(socket,
       streaming: true,
       data_points: [],
       anomalies: [],
       anomaly_count: 0
     )}
  end

  def handle_event("stop", _params, socket) do
    Phoenix.PubSub.unsubscribe(NxLiveViz.PubSub, "sensor:data")
    NxLiveViz.Data.CryptoAPI.deactivate()
    NxLiveViz.Data.SystemMetrics.deactivate()

    {:noreply, assign(socket, streaming: false)}
  end

  @impl true
  def handle_info({:sensor_data, _point}, %{assigns: %{streaming: false}} = socket) do
    {:noreply, socket}
  end

  def handle_info({:sensor_data, point}, socket) do
    window_size = socket.assigns.window_size
    points = [point.value | socket.assigns.data_points] |> Enum.take(@max_points)
    anomalies = [point.anomaly | socket.assigns.anomalies] |> Enum.take(@max_points)

    detection_result =
      if length(points) >= window_size and socket.assigns.detector do
        window =
          Enum.take(points, window_size)
          |> Nx.tensor()
          |> Nx.reshape({1, window_size})

        AnomalyDetector.predict(socket.assigns.detector, window)
      else
        nil
      end

    anomaly_count =
      if detection_result && detection_result.reconstruction_error > socket.assigns.threshold,
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

  defp chart_labels([]), do: []
  defp chart_labels(list), do: Enum.map(1..length(list), &to_string/1)

  defp safe_int(nil, default), do: default

  defp safe_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {n, _} -> n
      :error -> default
    end
  end

  defp safe_int(_, default), do: default

  defp safe_float(nil, default), do: default

  defp safe_float(val, default) when is_binary(val) do
    case Float.parse(val) do
      {n, _} -> n
      :error -> default
    end
  end

  defp safe_float(_, default), do: default

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path}>
    <div class="space-y-6">
      <div>
        <h1 class="text-lg font-semibold">Anomaly Detection</h1>
        <p class="text-sm text-gray-500 dark:text-gray-400">Axon autoencoder · Real-time streaming</p>
      </div>

      <form phx-change="update-params" id="anomaly-params">
        <div class="grid grid-cols-[auto_1fr_auto] items-center gap-x-4 gap-y-3 text-sm">
          <label class="text-gray-500 dark:text-gray-400">Source</label>
          <select
            name="source"
            disabled={@streaming}
            class="rounded border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 text-sm px-2 py-1"
          >
            <option :for={{key, label} <- @sources} value={key} selected={to_string(@source) == key}>
              {label}
            </option>
          </select>
          <div></div>

          <label class="text-gray-500 dark:text-gray-400">Window</label>
          <input
            type="range"
            name="window"
            min="5"
            max="50"
            value={@window_size}
            disabled={@streaming}
          />
          <span class="font-mono text-sm w-10 text-right">{@window_size}</span>

          <label class="text-gray-500 dark:text-gray-400">Threshold</label>
          <input
            type="range"
            name="threshold"
            min="0.1"
            max="2.0"
            step="0.1"
            value={@threshold}
            disabled={@streaming}
          />
          <span class="font-mono text-sm w-10 text-right">{@threshold}</span>
        </div>
      </form>

      <div class="flex items-center gap-3">
        <button
          :if={!@streaming}
          phx-click="start"
          type="button"
          class="px-4 py-1.5 bg-blue-600 hover:bg-blue-700 rounded text-sm font-medium text-white transition-colors"
        >
          Start
        </button>
        <button
          :if={@streaming}
          phx-click="stop"
          type="button"
          class="px-4 py-1.5 bg-red-600 hover:bg-red-700 rounded text-sm font-medium text-white transition-colors"
        >
          Stop
        </button>
        <span :if={@streaming} class="text-sm text-green-600 dark:text-green-400 flex items-center gap-1">
          <span class="w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse inline-block"></span>
          Streaming
        </span>
        <span class="text-sm text-gray-500 dark:text-gray-400 ml-auto">{@anomaly_count} anomalies detected</span>
      </div>

      <div
        id="anomaly-chart"
        phx-hook="LineChart"
        phx-update="ignore"
        data-max-points="200"
        data-x-label="Time"
        data-y-label="Signal Value"
        class="border border-gray-200 dark:border-gray-700 rounded-lg p-4 h-80"
      >
        <canvas></canvas>
      </div>
    </div>
    </Layouts.app>
    """
  end
end
