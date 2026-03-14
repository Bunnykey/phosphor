defmodule NxLiveVizWeb.SentimentLive do
  use NxLiveVizWeb, :live_view

  alias NxLiveViz.ML.Sentiment

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       text: "",
       result: nil,
       history: [],
       analyzing: false
     )}
  end

  @impl true
  def handle_event("analyze", %{"text" => text}, socket) when text != "" do
    socket = assign(socket, analyzing: true, text: text)

    pid = self()

    Task.start(fn ->
      result = Sentiment.analyze(text)
      send(pid, {:sentiment_result, text, result})
    end)

    {:noreply, socket}
  end

  def handle_event("analyze", _params, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:sentiment_result, text, result}, socket) do
    predictions = result.predictions

    scores = %{
      positive: find_score(predictions, "POS"),
      negative: find_score(predictions, "NEG"),
      neutral: find_score(predictions, "NEU")
    }

    top = Enum.max_by(predictions, & &1.score)

    history_entry = %{
      text: String.slice(text, 0, 50),
      label: top.label,
      score: top.score,
      time: DateTime.utc_now()
    }

    socket =
      socket
      |> assign(result: scores, analyzing: false)
      |> update(:history, fn h -> [history_entry | Enum.take(h, 19)] end)
      |> push_event("chart-data:gauge-chart", %{
        positive: scores.positive,
        negative: scores.negative,
        neutral: scores.neutral
      })
      |> push_event("chart-data:sentiment-trend", %{
        labels: socket.assigns.history
               |> Enum.take(20)
               |> Enum.reverse()
               |> Enum.with_index()
               |> Enum.map(fn {_, i} -> to_string(i + 1) end)
               |> then(fn l -> l ++ [to_string(length(l) + 1)] end),
        values: (socket.assigns.history
                |> Enum.take(20)
                |> Enum.reverse()
                |> Enum.map(fn h -> if h.label == "POS", do: h.score, else: -h.score end))
                ++ [if(top.label == "POS", do: top.score, else: -top.score)]
      })

    {:noreply, socket}
  end

  defp find_score(predictions, label) do
    case Enum.find(predictions, fn p -> p.label == label end) do
      nil -> 0.0
      p -> p.score
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <div>
        <h2 class="text-xl font-semibold">Sentiment Analysis</h2>
        <p class="text-sm text-gray-400">DistilBERT — enter text to analyze</p>
      </div>

      <div class="grid grid-cols-2 gap-4">
        <div class="space-y-4">
          <form phx-submit="analyze" class="space-y-2">
            <textarea
              name="text"
              rows="4"
              placeholder="Enter text to analyze sentiment..."
              class="w-full bg-gray-900 border border-gray-700 rounded-lg p-3 text-white resize-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
            >{@text}</textarea>
            <button
              type="submit"
              disabled={@analyzing}
              class="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 rounded-lg text-sm font-medium disabled:opacity-50"
            >
              {if @analyzing, do: "Analyzing...", else: "Analyze"}
            </button>
          </form>

          <div :if={@result} class="bg-gray-900 rounded-lg p-4 space-y-2">
            <div class="flex justify-between text-sm">
              <span class="text-green-400">Positive</span>
              <span class="font-mono">{Float.round(@result.positive * 100, 1)}%</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-red-400">Negative</span>
              <span class="font-mono">{Float.round(@result.negative * 100, 1)}%</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-gray-400">Neutral</span>
              <span class="font-mono">{Float.round(@result.neutral * 100, 1)}%</span>
            </div>
          </div>

          <div id="gauge-chart" phx-hook="GaugeChart" class="bg-gray-900 rounded-lg p-4 h-48">
            <canvas></canvas>
          </div>
        </div>

        <div class="space-y-4">
          <div id="sentiment-trend" phx-hook="LineChart" data-label="Sentiment Score" class="bg-gray-900 rounded-lg p-4 h-64">
            <canvas></canvas>
          </div>

          <div :if={@history != []} class="bg-gray-900 rounded-lg p-4 max-h-64 overflow-y-auto">
            <h3 class="text-sm font-medium text-gray-300 mb-2">History</h3>
            <div :for={h <- @history} class="flex justify-between text-xs py-1 text-gray-400 border-b border-gray-800">
              <span class="truncate max-w-[200px]">{h.text}</span>
              <span class={[
                "font-medium",
                if(h.label == "POS", do: "text-green-400", else: if(h.label == "NEG", do: "text-red-400", else: "text-gray-400"))
              ]}>
                {h.label} {Float.round(h.score * 100, 1)}%
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
