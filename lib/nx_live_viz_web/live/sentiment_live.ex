defmodule NxLiveVizWeb.SentimentLive do
  use NxLiveVizWeb, :live_view

  alias NxLiveViz.ML.Sentiment

  @impl true
  def mount(_params, _session, socket) do
    {history, sentiment_scores, sentiment_trend} = seed_sentiment_data()

    socket =
      socket
      |> assign(
        text: "",
        result: sentiment_scores,
        history: history,
        analyzing: false,
        error: nil
      )

    socket =
      if connected?(socket) do
        socket
        |> push_event("chart-data:gauge-chart", sentiment_scores)
        |> push_event("chart-data:sentiment-trend", sentiment_trend)
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("analyze", _params, %{assigns: %{analyzing: true}} = socket) do
    {:noreply, socket}
  end

  def handle_event("analyze", params, socket) do
    text = String.trim(params["text"] || "")

    cond do
      text == "" ->
        {:noreply, assign(socket, error: "Please enter some text to analyze.")}

      byte_size(text) > 10_000 ->
        {:noreply, assign(socket, error: "Text is too long (max 10,000 characters).")}

      true ->
        socket = assign(socket, analyzing: true, text: text, error: nil)

        pid = self()

        Task.start(fn ->
          try do
            result = Sentiment.analyze(text)
            send(pid, {:sentiment_result, text, result})
          rescue
            e -> send(pid, {:sentiment_error, Exception.message(e)})
          end
        end)

        {:noreply, socket}
    end
  end

  def handle_event("try-sample", %{"text" => text}, socket) do
    {:noreply, assign(socket, text: String.slice(text, 0, 10_000))}
  end

  @impl true
  def handle_info({:sentiment_error, _reason}, socket) do
    {:noreply, assign(socket, analyzing: false, error: "Analysis failed. Please try again.")}
  end

  @impl true
  def handle_info({:sentiment_result, text, result}, socket) do
    {label, dominant_score, scores} = map_sentiment(result.predictions)

    history_entry = %{
      text: String.slice(text, 0, 50),
      label: label,
      score: dominant_score,
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
                ++ [if(label == "POS", do: dominant_score, else: -dominant_score)]
      })

    {:noreply, socket}
  end

  defp seed_sentiment_data do
    now = DateTime.utc_now()

    history = [
      %{text: "The service was slow and the food was cold.", label: "NEG", score: 0.89, time: DateTime.add(now, -1, :minute)},
      %{text: "Just finished reading a fascinating book about AI.", label: "POS", score: 0.82, time: DateTime.add(now, -2, :minute)},
      %{text: "Terrible experience. Would not recommend to anyone.", label: "NEG", score: 0.94, time: DateTime.add(now, -3, :minute)},
      %{text: "The weather today is okay, nothing special.", label: "NEU", score: 0.78, time: DateTime.add(now, -4, :minute)},
      %{text: "I absolutely love this product! Best purchase ever!", label: "POS", score: 0.96, time: DateTime.add(now, -5, :minute)}
    ]

    # Sentiment scores based on the most recent analysis
    sentiment_scores = %{
      positive: 0.05,
      negative: 0.89,
      neutral: 0.06
    }

    # Trend points: one per history entry (oldest to newest), mapped to signed scores
    trend_entries = Enum.reverse(history)

    sentiment_trend = %{
      labels: trend_entries |> Enum.with_index(1) |> Enum.map(fn {_, i} -> to_string(i) end),
      values: trend_entries |> Enum.map(fn h -> if h.label == "POS", do: h.score, else: -h.score end)
    }

    {history, sentiment_scores, sentiment_trend}
  end

  # Map star ratings from nlptown/bert-base-multilingual-uncased-sentiment to sentiment categories.
  # Labels: "1 star", "2 stars", "3 stars", "4 stars", "5 stars"
  defp map_sentiment(predictions) do
    scores =
      Enum.reduce(predictions, %{positive: 0.0, negative: 0.0, neutral: 0.0}, fn pred, acc ->
        case pred.label do
          "5 stars" -> %{acc | positive: acc.positive + pred.score}
          "4 stars" -> %{acc | positive: acc.positive + pred.score}
          "3 stars" -> %{acc | neutral: acc.neutral + pred.score}
          "2 stars" -> %{acc | negative: acc.negative + pred.score}
          "1 star" -> %{acc | negative: acc.negative + pred.score}
          _ -> acc
        end
      end)

    label =
      cond do
        scores.positive > scores.negative and scores.positive > scores.neutral -> "POS"
        scores.negative > scores.positive and scores.negative > scores.neutral -> "NEG"
        true -> "NEU"
      end

    dominant_score = max(scores.positive, max(scores.negative, scores.neutral))

    {label, dominant_score, scores}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <div>
        <h2 class="text-xl font-semibold">Sentiment Analysis</h2>
        <p class="text-sm text-gray-500 dark:text-gray-400">Multilingual mBERT — enter text to analyze (supports Korean)</p>
      </div>

      <div class="grid grid-cols-2 gap-4">
        <div class="space-y-4">
          <form phx-submit="analyze" class="space-y-2">
            <textarea
              name="text"
              rows="4"
              placeholder="Enter text to analyze sentiment..."
              class="w-full bg-white dark:bg-gray-900 border border-gray-300 dark:border-gray-700 rounded-lg p-3 text-gray-900 dark:text-white resize-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
            >{@text}</textarea>
            <button
              type="submit"
              disabled={@analyzing}
              class="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 rounded-lg text-sm font-medium text-white disabled:opacity-50"
            >
              {if @analyzing, do: "Analyzing...", else: "Analyze"}
            </button>
          </form>

          <div :if={@error} class="mt-2 p-3 bg-red-50 dark:bg-red-500/10 border border-red-200 dark:border-red-500/20 rounded-lg text-red-600 dark:text-red-400 text-sm">
            {@error}
          </div>

          <div class="flex flex-wrap gap-2">
            <span class="text-xs text-gray-500 self-center">Quick try:</span>
            <button
              type="button"
              phx-click="try-sample"
              phx-value-text="This is absolutely wonderful, I am so happy with the results!"
              class="px-3 py-1 text-xs rounded-full bg-green-100 dark:bg-green-900/40 text-green-700 dark:text-green-400 border border-green-300 dark:border-green-700/50 hover:bg-green-200 dark:hover:bg-green-800/50 transition-colors"
            >
              Positive
            </button>
            <button
              type="button"
              phx-click="try-sample"
              phx-value-text="I am extremely disappointed and frustrated with this service."
              class="px-3 py-1 text-xs rounded-full bg-red-100 dark:bg-red-900/40 text-red-700 dark:text-red-400 border border-red-300 dark:border-red-700/50 hover:bg-red-200 dark:hover:bg-red-800/50 transition-colors"
            >
              Negative
            </button>
            <button
              type="button"
              phx-click="try-sample"
              phx-value-text="The meeting has been scheduled for tomorrow at 3pm."
              class="px-3 py-1 text-xs rounded-full bg-gray-100 dark:bg-gray-800/60 text-gray-600 dark:text-gray-400 border border-gray-300 dark:border-gray-600/50 hover:bg-gray-200 dark:hover:bg-gray-700/50 transition-colors"
            >
              Neutral
            </button>
            <button
              type="button"
              phx-click="try-sample"
              phx-value-text="이 제품은 품질은 좋지만 가격이 너무 비싸요."
              class="px-3 py-1 text-xs rounded-full bg-indigo-100 dark:bg-indigo-900/40 text-indigo-700 dark:text-indigo-400 border border-indigo-300 dark:border-indigo-700/50 hover:bg-indigo-200 dark:hover:bg-indigo-800/50 transition-colors"
            >
              Mixed
            </button>
          </div>

          <div :if={@result} class="bg-gray-100 dark:bg-gray-900 rounded-lg p-4 space-y-2">
            <div class="flex justify-between text-sm">
              <span class="text-green-600 dark:text-green-400">Positive</span>
              <span class="font-mono">{Float.round(@result.positive * 100, 1)}%</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-red-600 dark:text-red-400">Negative</span>
              <span class="font-mono">{Float.round(@result.negative * 100, 1)}%</span>
            </div>
            <div class="flex justify-between text-sm">
              <span class="text-gray-500 dark:text-gray-400">Neutral</span>
              <span class="font-mono">{Float.round(@result.neutral * 100, 1)}%</span>
            </div>
          </div>

          <div id="gauge-chart" phx-hook="GaugeChart" phx-update="ignore" class="bg-gray-100 dark:bg-gray-900 rounded-lg p-4 h-48">
            <canvas></canvas>
          </div>
        </div>

        <div class="space-y-4">
          <div id="sentiment-trend" phx-hook="LineChart" phx-update="ignore" data-label="Sentiment Score" class="bg-gray-100 dark:bg-gray-900 rounded-lg p-4 h-64">
            <canvas></canvas>
          </div>

          <div :if={@history != []} class="bg-gray-100 dark:bg-gray-900 rounded-lg p-4 max-h-64 overflow-y-auto">
            <h3 class="text-sm font-medium text-gray-600 dark:text-gray-300 mb-2">History</h3>
            <div :for={h <- @history} class="flex justify-between text-xs py-1 text-gray-500 dark:text-gray-400 border-b border-gray-200 dark:border-gray-800">
              <span class="truncate max-w-[200px]">{h.text}</span>
              <span class={[
                "font-medium",
                if(h.label == "POS", do: "text-green-600 dark:text-green-400", else: if(h.label == "NEG", do: "text-red-600 dark:text-red-400", else: "text-gray-500 dark:text-gray-400"))
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
