defmodule NxLiveVizWeb.ImageLive do
  use NxLiveVizWeb, :live_view

  alias NxLiveViz.ML.ImageClassifier

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:predictions, [])
     |> assign(:history, [])
     |> assign(:classifying, false)
     |> assign(:preview_url, nil)
     |> allow_upload(:image,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 1,
       max_file_size: 10_000_000,
       auto_upload: true,
       progress: &handle_progress/3
     )}
  end

  defp handle_progress(:image, entry, socket) do
    if entry.done? do
      binary =
        consume_uploaded_entry(socket, entry, fn %{path: path} ->
          {:ok, File.read!(path)}
        end)

      filename = entry.client_name
      pid = self()

      Task.start(fn ->
        try do
          result = ImageClassifier.classify(binary)
          send(pid, {:classification_result, filename, result})
        rescue
          _ -> send(pid, {:classification_error, filename})
        end
      end)

      {:noreply, assign(socket, :classifying, true)}
    else
      {:noreply, assign(socket, :classifying, true)}
    end
  end

  @impl true
  def handle_info({:classification_result, filename, result}, socket) do
    predictions =
      result.predictions
      |> Enum.map(fn %{label: label, score: score} ->
        %{label: label, score: Float.round(score, 4)}
      end)

    history_entry = %{
      filename: filename,
      top_label: hd(predictions).label,
      score: hd(predictions).score,
      time: DateTime.utc_now()
    }

    socket =
      socket
      |> assign(:predictions, predictions)
      |> assign(:classifying, false)
      |> update(:history, fn h -> [history_entry | Enum.take(h, 9)] end)
      |> push_event("chart-data:image-chart", %{
        labels: Enum.map(predictions, & &1.label),
        values: Enum.map(predictions, & &1.score)
      })

    {:noreply, socket}
  end

  def handle_info({:classification_error, _filename}, socket) do
    {:noreply, assign(socket, classifying: false)}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <div>
        <h2 class="text-xl font-semibold">Image Classification</h2>
        <p class="text-sm text-gray-400">ResNet-50 — drag & drop an image</p>
      </div>

      <div class="grid grid-cols-2 gap-4">
        <div class="space-y-4">
          <form phx-change="validate" class="bg-gray-900 rounded-lg p-6 border-2 border-dashed border-gray-700 text-center"
                phx-drop-target={@uploads.image.ref}>
            <.live_file_input upload={@uploads.image} class="hidden" />
            <p class="text-gray-400">Drop image here or click to upload</p>

            <div :for={entry <- @uploads.image.entries} class="mt-4">
              <.live_img_preview entry={entry} class="mx-auto max-h-48 rounded" />
              <progress value={entry.progress} max="100" class="w-full mt-2">{entry.progress}%</progress>
            </div>
          </form>

          <div :if={@classifying} class="text-center text-indigo-400">
            Classifying...
          </div>

          <div :if={@predictions != []} class="bg-gray-900 rounded-lg p-4">
            <h3 class="text-sm font-medium text-gray-300 mb-2">Results</h3>
            <div :for={pred <- @predictions} class="flex justify-between text-sm py-1">
              <span class="text-gray-300 truncate max-w-[200px]">{pred.label}</span>
              <span class="text-indigo-400 font-mono">{Float.round(pred.score * 100, 1)}%</span>
            </div>
          </div>
        </div>

        <div class="space-y-4">
          <div id="image-chart" phx-hook="BarChart" data-label="Confidence" class="bg-gray-900 rounded-lg p-4 h-64">
            <canvas></canvas>
          </div>

          <div :if={@history != []} class="bg-gray-900 rounded-lg p-4">
            <h3 class="text-sm font-medium text-gray-300 mb-2">Recent</h3>
            <div :for={h <- @history} class="flex justify-between text-xs py-1 text-gray-400">
              <span class="truncate max-w-[150px]">{h.filename}</span>
              <span>{h.top_label}</span>
              <span class="text-indigo-400">{Float.round(h.score * 100, 1)}%</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
