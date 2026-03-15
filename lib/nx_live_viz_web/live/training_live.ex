defmodule NxLiveVizWeb.TrainingLive do
  use NxLiveVizWeb, :live_view

  alias NxLiveViz.ML.Trainer
  alias NxLiveViz.ML.TrainingStore

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(NxLiveViz.PubSub, "training:metrics")
    end

    socket =
      case TrainingStore.load() do
        {:ok, saved} ->
          # Restore persisted training state
          display_losses = Enum.reverse(saved.loss_history)
          display_accuracies = Enum.reverse(saved.accuracy_history)
          labels = chart_labels(saved.loss_history)

          socket
          |> assign(
            training: false,
            task_ref: nil,
            task_pid: nil,
            epochs: 10,
            learning_rate: 0.001,
            batch_size: 32,
            losses: saved.loss_history,
            accuracies: saved.accuracy_history,
            current_epoch: saved.current_epoch,
            current_iteration: saved.current_iteration,
            current_loss: saved.current_loss,
            current_accuracy: saved.current_accuracy,
            histogram: saved.histogram,
            status: saved.status
          )
          |> push_event("chart-data:loss-chart", %{labels: labels, values: display_losses})
          |> push_event("chart-data:accuracy-chart", %{labels: labels, values: display_accuracies})
          |> then(fn s ->
            if saved.histogram, do: push_event(s, "chart-data:weight-histogram", saved.histogram), else: s
          end)

        :error ->
          # No persisted state — use seed data
          socket
          |> assign(training: false, task_ref: nil, task_pid: nil, epochs: 10, learning_rate: 0.001, batch_size: 32)
          |> apply_seed_state()
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("start", _params, %{assigns: %{training: true}} = socket) do
    {:noreply, socket}
  end

  def handle_event("start", _params, socket) do
    task =
      Task.async(fn ->
        Trainer.train(
          epochs: socket.assigns.epochs,
          learning_rate: socket.assigns.learning_rate,
          batch_size: socket.assigns.batch_size
        )
      end)

    {:noreply,
     assign(socket,
       training: true,
       task_ref: task.ref,
       task_pid: task.pid,
       losses: [],
       accuracies: [],
       current_epoch: 0,
       current_iteration: 0,
       current_loss: nil,
       current_accuracy: nil,
       histogram: nil,
       status: :training
     )}
  end

  def handle_event("stop", _params, socket) do
    if socket.assigns.task_pid do
      Process.demonitor(socket.assigns.task_ref, [:flush])
      Process.exit(socket.assigns.task_pid, :kill)
    end

    {:noreply, assign(socket, training: false, task_ref: nil, task_pid: nil)}
  end

  def handle_event("reset", _params, socket) do
    TrainingStore.clear()
    {:noreply, apply_seed_state(socket)}
  end

  def handle_event("update-params", params, socket) do
    epochs = safe_int(params["epochs"], socket.assigns.epochs) |> max(1) |> min(50)
    lr = safe_float(params["learning_rate"], socket.assigns.learning_rate) |> max(0.0001) |> min(0.01)
    batch_size = safe_int(params["batch_size"], socket.assigns.batch_size) |> max(8) |> min(128)

    {:noreply, assign(socket, epochs: epochs, learning_rate: lr, batch_size: batch_size)}
  end

  @impl true
  def handle_info({:training_metrics, metrics}, socket) do
    losses = [metrics.loss | socket.assigns.losses]
    accuracies = [metrics.accuracy | socket.assigns.accuracies]
    display_losses = Enum.reverse(losses)
    display_accuracies = Enum.reverse(accuracies)
    labels = chart_labels(losses)

    socket =
      socket
      |> assign(
        losses: losses,
        accuracies: accuracies,
        current_epoch: metrics.epoch,
        current_iteration: metrics.iteration,
        current_loss: metrics.loss,
        current_accuracy: metrics.accuracy
      )
      |> push_event("chart-data:loss-chart", %{
        labels: labels,
        values: display_losses
      })
      |> push_event("chart-data:accuracy-chart", %{
        labels: labels,
        values: display_accuracies
      })

    save_training_snapshot(socket, :training)

    {:noreply, socket}
  end

  def handle_info({:weight_histogram, histogram}, socket) do
    socket =
      socket
      |> assign(:histogram, histogram)
      |> push_event("chart-data:weight-histogram", histogram)

    save_training_snapshot(socket)

    {:noreply, socket}
  end

  def handle_info({ref, _result}, socket) when ref == socket.assigns.task_ref do
    Process.demonitor(ref, [:flush])

    socket = assign(socket, training: false, task_ref: nil, task_pid: nil, status: :completed)

    save_training_snapshot(socket, :completed)

    {:noreply, socket}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, socket)
      when ref == socket.assigns.task_ref do
    {:noreply, assign(socket, training: false, task_ref: nil, task_pid: nil)}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  defp save_training_snapshot(socket, status \\ nil) do
    a = socket.assigns

    TrainingStore.save(%{
      loss_history: a.losses,
      accuracy_history: a.accuracies,
      histogram: a.histogram,
      current_epoch: a.current_epoch,
      current_iteration: a.current_iteration,
      current_loss: a.current_loss,
      current_accuracy: a.current_accuracy,
      status: status || a.status
    })
  end

  defp apply_seed_state(socket) do
    {seed_losses, seed_accuracies, seed_histogram} = seed_training_data()
    reversed_losses = Enum.reverse(seed_losses)
    reversed_accuracies = Enum.reverse(seed_accuracies)
    labels = chart_labels(reversed_losses)

    socket
    |> assign(
      losses: seed_losses,
      accuracies: seed_accuracies,
      histogram: seed_histogram,
      current_epoch: 5,
      current_iteration: 50,
      current_loss: 0.15,
      current_accuracy: 0.95,
      status: :completed
    )
    |> push_event("chart-data:loss-chart", %{labels: labels, values: reversed_losses})
    |> push_event("chart-data:accuracy-chart", %{labels: labels, values: reversed_accuracies})
    |> push_event("chart-data:weight-histogram", seed_histogram)
  end

  defp chart_labels(list), do: Enum.map(1..length(list), &to_string/1)

  defp safe_int(value, default) do
    case Integer.parse(to_string(value)) do
      {v, _} -> v
      :error -> default
    end
  end

  defp safe_float(value, default) do
    case Float.parse(to_string(value)) do
      {v, _} -> v
      :error -> default
    end
  end

  # Generates realistic demo data for a completed 5-epoch, 50-iteration training run.
  # Loss follows an exponential decay from ~2.3 to ~0.15 with noise.
  # Accuracy follows a sigmoid-like curve from ~0.10 to ~0.95.
  # Histogram is a bell curve centered around 0 with 30 bins.
  defp seed_training_data do
    # Use a fixed seed for deterministic demo data
    :rand.seed(:exsss, {42, 137, 256})

    num_points = 25

    # Loss: exponential decay from ~2.3 to ~0.15 with some noise
    loss_history =
      for i <- 0..(num_points - 1) do
        t = i / (num_points - 1)
        base = 2.3 * :math.exp(-3.5 * t) + 0.15
        noise = (:rand.uniform() - 0.5) * 0.08 * (1 - t * 0.7)
        Float.round(max(base + noise, 0.05), 4)
      end

    # Accuracy: sigmoid-like curve from ~0.10 to ~0.95
    accuracy_history =
      for i <- 0..(num_points - 1) do
        t = i / (num_points - 1)
        base = 0.10 + 0.85 / (1.0 + :math.exp(-8.0 * (t - 0.35)))
        noise = (:rand.uniform() - 0.5) * 0.03 * (1 - t * 0.5)
        Float.round(min(max(base + noise, 0.05), 0.99), 4)
      end

    # Weight histogram: bell curve centered around 0 with 30 bins
    num_bins = 30
    min_val = -0.3
    max_val = 0.3
    bin_width = (max_val - min_val) / num_bins
    sigma = 0.08

    bins =
      for i <- 0..(num_bins - 1) do
        Float.round(min_val + i * bin_width, 3) |> to_string()
      end

    counts =
      for i <- 0..(num_bins - 1) do
        center = min_val + (i + 0.5) * bin_width
        # Gaussian bell curve
        gaussian = :math.exp(-(center * center) / (2.0 * sigma * sigma))
        # Scale to reasonable counts and add minor noise
        base_count = round(gaussian * 3500)
        noise = round((:rand.uniform() - 0.5) * 80)
        max(base_count + noise, 0)
      end

    histogram = %{bins: bins, counts: counts}

    {loss_history, accuracy_history, histogram}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-xl font-semibold">Training Visualization</h2>
          <p class="text-sm text-gray-500 dark:text-gray-400">MNIST classifier — watch the model learn</p>
        </div>
        <div class="flex gap-2">
          <button
            :if={!@training}
            phx-click="start"
            class="px-4 py-2 bg-green-600 hover:bg-green-700 rounded-lg text-sm font-medium text-white"
          >
            Start Training
          </button>
          <button
            :if={@training}
            phx-click="stop"
            class="px-4 py-2 bg-red-600 hover:bg-red-700 rounded-lg text-sm font-medium text-white"
          >
            Stop
          </button>
          <button
            phx-click="reset"
            class="px-4 py-2 bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 rounded-lg text-sm font-medium"
          >
            Reset
          </button>
        </div>
      </div>

      <!-- Hyperparameter controls -->
      <form phx-change="update-params" class="flex gap-4 bg-gray-100 dark:bg-gray-900 rounded-lg p-4">
        <div class="flex-1">
          <label class="block text-xs text-gray-500 dark:text-gray-400 mb-1">Epochs</label>
          <input
            type="range" name="epochs" min="1" max="50" value={@epochs}
            disabled={@training}
            class="w-full"
          />
          <span class="text-xs text-gray-600 dark:text-gray-300">{@epochs}</span>
        </div>
        <div class="flex-1">
          <label class="block text-xs text-gray-500 dark:text-gray-400 mb-1">Learning Rate</label>
          <input
            type="range" name="learning_rate" min="0.0001" max="0.01" step="0.0001" value={@learning_rate}
            disabled={@training}
            class="w-full"
          />
          <span class="text-xs text-gray-600 dark:text-gray-300">{@learning_rate}</span>
        </div>
        <div class="flex-1">
          <label class="block text-xs text-gray-500 dark:text-gray-400 mb-1">Batch Size</label>
          <input
            type="range" name="batch_size" min="8" max="128" step="8" value={@batch_size}
            disabled={@training}
            class="w-full"
          />
          <span class="text-xs text-gray-600 dark:text-gray-300">{@batch_size}</span>
        </div>
      </form>

      <div class="text-sm text-gray-500 dark:text-gray-400">
        Epoch: {@current_epoch} | Iteration: {@current_iteration}
      </div>

      <div class="grid grid-cols-2 gap-4">
        <div id="loss-chart" phx-hook="LineChart" phx-update="ignore" data-label="Loss" class="bg-gray-100 dark:bg-gray-900 rounded-lg p-4 h-64">
          <canvas></canvas>
        </div>
        <div id="accuracy-chart" phx-hook="LineChart" phx-update="ignore" data-label="Accuracy" class="bg-gray-100 dark:bg-gray-900 rounded-lg p-4 h-64">
          <canvas></canvas>
        </div>
      </div>

      <div id="weight-histogram" phx-hook="HistogramChart" phx-update="ignore" class="bg-gray-100 dark:bg-gray-900 rounded-lg p-4 h-64">
        <canvas></canvas>
      </div>
    </div>
    """
  end
end
