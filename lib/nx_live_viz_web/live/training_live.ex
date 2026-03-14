defmodule NxLiveVizWeb.TrainingLive do
  use NxLiveVizWeb, :live_view

  alias NxLiveViz.ML.Trainer

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(NxLiveViz.PubSub, "training:metrics")
    end

    {:ok,
     assign(socket,
       training: false,
       task_ref: nil,
       epochs: 10,
       learning_rate: 0.001,
       batch_size: 32,
       losses: [],
       accuracies: [],
       current_epoch: 0,
       current_iteration: 0,
       histogram: nil
     )}
  end

  @impl true
  def handle_event("start", _params, socket) do
    task =
      Task.async(fn ->
        Trainer.train(
          epochs: socket.assigns.epochs,
          learning_rate: socket.assigns.learning_rate,
          batch_size: socket.assigns.batch_size
        )
      end)

    {:noreply, assign(socket, training: true, task_ref: task.ref, losses: [], accuracies: [])}
  end

  def handle_event("stop", _params, socket) do
    {:noreply, assign(socket, training: false)}
  end

  def handle_event("reset", _params, socket) do
    {:noreply,
     assign(socket,
       training: false,
       losses: [],
       accuracies: [],
       current_epoch: 0,
       current_iteration: 0,
       histogram: nil
     )}
  end

  def handle_event("update-params", params, socket) do
    socket =
      socket
      |> assign(:epochs, String.to_integer(params["epochs"] || "10"))
      |> assign(:learning_rate, String.to_float(params["learning_rate"] || "0.001"))
      |> assign(:batch_size, String.to_integer(params["batch_size"] || "32"))

    {:noreply, socket}
  end

  @impl true
  def handle_info({:training_metrics, metrics}, socket) do
    losses = socket.assigns.losses ++ [metrics.loss]
    accuracies = socket.assigns.accuracies ++ [metrics.accuracy]
    labels = Enum.map(1..length(losses), &to_string/1)

    socket =
      socket
      |> assign(
        losses: losses,
        accuracies: accuracies,
        current_epoch: metrics.epoch,
        current_iteration: metrics.iteration
      )
      |> push_event("chart-data:loss-chart", %{
        labels: labels,
        values: losses
      })
      |> push_event("chart-data:accuracy-chart", %{
        labels: labels,
        values: accuracies
      })

    {:noreply, socket}
  end

  def handle_info({:weight_histogram, histogram}, socket) do
    socket =
      socket
      |> assign(:histogram, histogram)
      |> push_event("chart-data:weight-histogram", histogram)

    {:noreply, socket}
  end

  def handle_info({ref, _result}, socket) when ref == socket.assigns.task_ref do
    Process.demonitor(ref, [:flush])
    {:noreply, assign(socket, training: false, task_ref: nil)}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, socket)
      when ref == socket.assigns.task_ref do
    {:noreply, assign(socket, training: false, task_ref: nil)}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <div class="flex items-center justify-between">
        <div>
          <h2 class="text-xl font-semibold">Training Visualization</h2>
          <p class="text-sm text-gray-400">MNIST classifier — watch the model learn</p>
        </div>
        <div class="flex gap-2">
          <button
            :if={!@training}
            phx-click="start"
            class="px-4 py-2 bg-green-600 hover:bg-green-700 rounded-lg text-sm font-medium"
          >
            Start Training
          </button>
          <button
            :if={@training}
            phx-click="stop"
            class="px-4 py-2 bg-red-600 hover:bg-red-700 rounded-lg text-sm font-medium"
          >
            Stop
          </button>
          <button
            phx-click="reset"
            class="px-4 py-2 bg-gray-700 hover:bg-gray-600 rounded-lg text-sm font-medium"
          >
            Reset
          </button>
        </div>
      </div>

      <!-- Hyperparameter controls -->
      <form phx-change="update-params" class="flex gap-4 bg-gray-900 rounded-lg p-4">
        <div class="flex-1">
          <label class="block text-xs text-gray-400 mb-1">Epochs</label>
          <input
            type="range" name="epochs" min="1" max="50" value={@epochs}
            disabled={@training}
            class="w-full"
          />
          <span class="text-xs text-gray-300">{@epochs}</span>
        </div>
        <div class="flex-1">
          <label class="block text-xs text-gray-400 mb-1">Learning Rate</label>
          <input
            type="range" name="learning_rate" min="0.0001" max="0.01" step="0.0001" value={@learning_rate}
            disabled={@training}
            class="w-full"
          />
          <span class="text-xs text-gray-300">{@learning_rate}</span>
        </div>
        <div class="flex-1">
          <label class="block text-xs text-gray-400 mb-1">Batch Size</label>
          <input
            type="range" name="batch_size" min="8" max="128" step="8" value={@batch_size}
            disabled={@training}
            class="w-full"
          />
          <span class="text-xs text-gray-300">{@batch_size}</span>
        </div>
      </form>

      <div class="text-sm text-gray-400">
        Epoch: {@current_epoch} | Iteration: {@current_iteration}
      </div>

      <div class="grid grid-cols-2 gap-4">
        <div id="loss-chart" phx-hook="LineChart" data-label="Loss" class="bg-gray-900 rounded-lg p-4 h-64">
          <canvas></canvas>
        </div>
        <div id="accuracy-chart" phx-hook="LineChart" data-label="Accuracy" class="bg-gray-900 rounded-lg p-4 h-64">
          <canvas></canvas>
        </div>
      </div>

      <div id="weight-histogram" phx-hook="HistogramChart" class="bg-gray-900 rounded-lg p-4 h-64">
        <canvas></canvas>
      </div>
    </div>
    """
  end
end
