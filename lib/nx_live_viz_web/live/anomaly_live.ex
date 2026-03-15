defmodule NxLiveVizWeb.AnomalyLive do
  use NxLiveVizWeb, :live_view

  alias NxLiveViz.ML.AnomalyDetector

  @window_size 20
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
        sources: @sources,
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

  def handle_event("select-source", %{"source" => source}, socket) do
    case Map.fetch(@source_map, source) do
      {:ok, source_atom} ->
        {:noreply, assign(socket, source: source_atom)}

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

  defp chart_labels([]), do: []
  defp chart_labels(list), do: Enum.map(1..length(list), &to_string/1)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <div>
        <h2 class="text-xl font-semibold">Anomaly Detection</h2>
        <p class="text-sm text-gray-500 dark:text-gray-400">Autoencoder-based real-time anomaly detection</p>
      </div>

      <%!-- Control Panel --%>
      <div class="bg-gray-50 dark:bg-gray-900 border border-gray-200 dark:border-gray-800 rounded-lg p-4 space-y-3">
        <div class="flex items-center justify-between">
          <span class="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide">Control Panel</span>
          <div class="flex items-center gap-2">
            <span :if={@streaming} class="inline-flex items-center gap-1.5 text-xs text-green-600 dark:text-green-400">
              <span class="w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse"></span>
              Streaming
            </span>
            <span class="text-xs text-red-600 dark:text-red-400 font-mono">
              {@anomaly_count} anomalies
            </span>
          </div>
        </div>

        <div class="grid grid-cols-1 sm:grid-cols-[1fr_auto] gap-3">
          <%!-- Source selection --%>
          <div class="space-y-1.5">
            <label class="text-xs text-gray-500 dark:text-gray-400">Data Source</label>
            <div class="flex flex-wrap gap-1.5">
              <%= for {key, label} <- @sources do %>
                <button
                  phx-click="select-source"
                  phx-value-source={key}
                  disabled={@streaming}
                  class={[
                    "px-3 py-1.5 rounded text-xs font-medium border transition-colors",
                    if(to_string(@source) == key,
                      do: "bg-indigo-600 border-indigo-600 text-white dark:bg-indigo-500 dark:border-indigo-500",
                      else: "bg-white dark:bg-gray-800 border-gray-300 dark:border-gray-700 text-gray-700 dark:text-gray-300 hover:border-indigo-400 dark:hover:border-indigo-500"
                    ),
                    if(@streaming, do: "opacity-50 cursor-not-allowed", else: "")
                  ]}
                >
                  {label}
                </button>
              <% end %>
            </div>
          </div>

          <%!-- Action button --%>
          <div class="flex items-end">
            <button
              :if={!@streaming}
              phx-click="start"
              class="px-5 py-1.5 bg-green-600 hover:bg-green-700 rounded text-sm font-medium text-white transition-colors"
            >
              Start
            </button>
            <button
              :if={@streaming}
              phx-click="stop"
              class="px-5 py-1.5 bg-red-600 hover:bg-red-700 rounded text-sm font-medium text-white transition-colors"
            >
              Stop
            </button>
          </div>
        </div>

        <%!-- Parameters --%>
        <div class="flex gap-4 text-xs text-gray-500 dark:text-gray-400 pt-1 border-t border-gray-200 dark:border-gray-800">
          <span>Window: <span class="font-mono text-gray-700 dark:text-gray-300">{@window_size}</span></span>
          <span>Threshold: <span class="font-mono text-gray-700 dark:text-gray-300">0.5</span></span>
          <span>Max points: <span class="font-mono text-gray-700 dark:text-gray-300">{@max_points}</span></span>
        </div>
      </div>

      <%!-- Chart --%>
      <div id="anomaly-chart" phx-hook="LineChart" phx-update="ignore" data-max-points="200" data-x-label="Time" data-y-label="Signal Value" class="bg-gray-100 dark:bg-gray-900 rounded-lg p-4 h-80">
        <canvas></canvas>
      </div>
    </div>
    """
  end
end
