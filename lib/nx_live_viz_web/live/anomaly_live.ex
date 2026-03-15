defmodule NxLiveVizWeb.AnomalyLive do
  use NxLiveVizWeb, :live_view

  alias NxLiveViz.ML.AnomalyDetector

  @window_size 20
  @max_points 200

  @seed_count 30
  @anomaly_indices [7, 15, 22, 28]

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(NxLiveViz.PubSub, "sensor:data")
    end

    {detector, initial_points, initial_anomalies, initial_anomaly_count} =
      if connected?(socket) do
        det = AnomalyDetector.cached_detector(input_size: @window_size)
        seed = seed_data()
        points = seed |> Enum.map(& &1.value) |> Enum.reverse()
        anomalies = seed |> Enum.map(& &1.anomaly) |> Enum.reverse()
        count = Enum.count(seed, & &1.anomaly)
        {det, points, anomalies, count}
      else
        {nil, [], [], 0}
      end

    socket =
      assign(socket,
        data_points: initial_points,
        anomalies: initial_anomalies,
        detector: detector,
        source: :simulator,
        anomaly_count: initial_anomaly_count
      )

    socket =
      if connected?(socket) and initial_points != [] do
        display_points = Enum.reverse(initial_points)
        display_anomalies = Enum.reverse(initial_anomalies)
        labels = Enum.map(1..length(display_points), &to_string/1)

        push_event(socket, "chart-data:anomaly-chart", %{
          labels: labels,
          values: display_points,
          anomalies: display_anomalies
        })
      else
        socket
      end

    {:ok, socket}
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
  def handle_event("change-source", %{"source" => source}, socket) do
    source_atom = String.to_existing_atom(source)
    NxLiveViz.set_data_source(source_atom)
    {:noreply, assign(socket, source: source_atom, data_points: [], anomalies: [], anomaly_count: 0)}
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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-xl font-semibold">Anomaly Detection</h2>
          <p class="text-sm text-gray-500 dark:text-gray-400">Autoencoder-based real-time anomaly detection</p>
        </div>
        <div class="flex items-center gap-4">
          <span class="text-sm text-red-600 dark:text-red-400">
            Anomalies detected: {@anomaly_count}
          </span>
          <select
            phx-change="change-source"
            name="source"
            class="bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-700 rounded px-3 py-1 text-sm text-gray-900 dark:text-gray-100"
          >
            <option value="simulator" selected={@source == :simulator}>Simulator</option>
            <option value="crypto" selected={@source == :crypto}>Crypto API</option>
            <option value="system" selected={@source == :system}>System Metrics</option>
          </select>
        </div>
      </div>

      <div id="anomaly-chart" phx-hook="LineChart" phx-update="ignore" class="bg-gray-100 dark:bg-gray-900 rounded-lg p-4 h-80">
        <canvas></canvas>
      </div>
    </div>
    """
  end
end
