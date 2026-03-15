defmodule NxLiveVizWeb.ImageLive do
  use NxLiveVizWeb, :live_view

  alias NxLiveViz.ML.ImageClassifier

  @impl true
  def mount(_params, _session, socket) do
    {seed_predictions, seed_history, seed_label, seed_score} = seed_classification_data()

    {:ok,
     socket
     |> assign(:predictions, seed_predictions)
     |> assign(:history, seed_history)
     |> assign(:result_label, seed_label)
     |> assign(:result_score, seed_score)
     |> assign(:classifying, false)
     |> assign(:preview_url, nil)
     |> assign(:error, nil)
     |> allow_upload(:image,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 1,
       max_file_size: 10_000_000,
       auto_upload: true,
       progress: &handle_progress/3
     )}
  end

  defp seed_classification_data do
    predictions = [
      %{label: "daisy", score: 0.95},
      %{label: "sunflower", score: 0.03},
      %{label: "pot", score: 0.01},
      %{label: "vase", score: 0.005},
      %{label: "bee", score: 0.003}
    ]

    history = [
      %{
        filename: "sample_flower.jpg",
        top_label: "daisy",
        score: 0.95,
        time: ~U[2026-03-15 09:30:00Z]
      },
      %{
        filename: "sample_cat.jpg",
        top_label: "tabby cat",
        score: 0.92,
        time: ~U[2026-03-15 09:25:00Z]
      },
      %{
        filename: "sample_car.jpg",
        top_label: "sports car",
        score: 0.87,
        time: ~U[2026-03-15 09:20:00Z]
      }
    ]

    top = hd(predictions)
    {predictions, history, top.label, top.score}
  end

  defp handle_progress(:image, entry, socket) do
    if entry.done? and not socket.assigns.classifying do
      binary =
        consume_uploaded_entry(socket, entry, fn %{path: path} ->
          {:ok, File.read!(path)}
        end)

      ext = entry.client_name |> Path.extname() |> String.trim_leading(".") |> String.downcase()

      mime_ext = case ext do
        "jpg" -> "jpeg"
        "jpeg" -> "jpeg"
        "png" -> "png"
        "webp" -> "webp"
        _ -> "png"
      end

      data_url = "data:image/#{mime_ext};base64,#{Base.encode64(binary)}"

      filename = entry.client_name |> String.slice(0, 255) |> String.replace(~r/[[:cntrl:]]/, "")
      pid = self()

      Task.start(fn ->
        try do
          result = ImageClassifier.classify(binary)
          send(pid, {:classification_result, filename, result})
        rescue
          e -> send(pid, {:classification_error, filename, Exception.message(e)})
        end
      end)

      {:noreply, socket |> assign(:classifying, true) |> assign(:error, nil) |> assign(:preview_url, data_url)}
    else
      {:noreply, socket}
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

  def handle_info({:classification_error, _filename, _reason}, socket) do
    {:noreply,
     assign(socket,
       classifying: false,
       error: "Classification failed. Please try a different image."
     )}
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
        <p class="text-sm text-gray-500 dark:text-gray-400">ResNet-50 — drag & drop an image</p>
      </div>

      <div class="grid grid-cols-2 gap-4">
        <div class="space-y-4">
          <form phx-change="validate" class="bg-gray-100 dark:bg-gray-900 rounded-lg p-6 border-2 border-dashed border-gray-300 dark:border-gray-700 text-center"
                phx-drop-target={@uploads.image.ref}>
            <.live_file_input upload={@uploads.image} class="hidden" />
            <p class="text-gray-500 dark:text-gray-400">Drop image here or click to upload</p>

            <div :for={entry <- @uploads.image.entries} class="mt-4">
              <.live_img_preview entry={entry} class="mx-auto max-h-48 rounded" />
              <progress value={entry.progress} max="100" class="w-full mt-2">{entry.progress}%</progress>
            </div>
          </form>

          <div :if={@classifying} class="text-center text-indigo-600 dark:text-indigo-400">
            Classifying...
          </div>

          <div :if={@error} class="mt-4 p-3 bg-red-50 dark:bg-red-500/10 border border-red-200 dark:border-red-500/20 rounded-lg text-red-600 dark:text-red-400 text-sm">
            {@error}
          </div>

          <div :if={@predictions != []} class="bg-gray-100 dark:bg-gray-900 rounded-lg p-4">
            <h3 class="text-sm font-medium text-gray-600 dark:text-gray-300 mb-2">Results</h3>
            <img :if={@preview_url} src={@preview_url} class="max-w-xs rounded-lg mb-4" />
            <div :for={pred <- @predictions} class="flex justify-between text-sm py-1">
              <span class="text-gray-700 dark:text-gray-300 truncate max-w-[200px]">{pred.label}</span>
              <span class="text-indigo-600 dark:text-indigo-400 font-mono">{Float.round(pred.score * 100, 1)}%</span>
            </div>
          </div>
        </div>

        <div class="space-y-4">
          <div id="image-chart" phx-hook="BarChart" phx-update="ignore" data-label="Confidence" class="bg-gray-100 dark:bg-gray-900 rounded-lg p-4 h-64">
            <canvas></canvas>
          </div>

          <div :if={@history != []} class="bg-gray-100 dark:bg-gray-900 rounded-lg p-4">
            <h3 class="text-sm font-medium text-gray-600 dark:text-gray-300 mb-2">Recent</h3>
            <div :for={h <- @history} class="flex justify-between text-xs py-1 text-gray-500 dark:text-gray-400">
              <span class="truncate max-w-[150px]">{h.filename}</span>
              <span>{h.top_label}</span>
              <span class="text-indigo-600 dark:text-indigo-400">{Float.round(h.score * 100, 1)}%</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
