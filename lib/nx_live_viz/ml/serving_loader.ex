defmodule NxLiveViz.ML.ServingLoader do
  @moduledoc "Loads ML servings asynchronously with retry on failure."
  use GenServer
  require Logger

  @retry_interval 30_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    send(self(), :load_servings)
    {:ok, %{loaded: MapSet.new()}}
  end

  @impl true
  def handle_info(:load_servings, state) do
    state = try_load(:image, &NxLiveViz.ML.ImageClassifier.serving/0, NxLiveViz.ImageServing, state)
    state = try_load(:sentiment, &NxLiveViz.ML.Sentiment.serving/0, NxLiveViz.SentimentServing, state)

    if MapSet.size(state.loaded) < 2 do
      Logger.info("ServingLoader: #{2 - MapSet.size(state.loaded)} serving(s) pending, retrying in 30s")
      Process.send_after(self(), :load_servings, @retry_interval)
    else
      Logger.info("ServingLoader: all ML servings loaded")
    end

    {:noreply, state}
  end

  defp try_load(label, serving_fn, name, state) do
    if MapSet.member?(state.loaded, label) do
      state
    else
      try do
        serving = serving_fn.()

        spec = %{
          id: name,
          start:
            {Nx.Serving, :start_link,
             [[serving: serving, name: name, batch_size: 4, batch_timeout: 100]]}
        }

        case Supervisor.start_child(NxLiveViz.Supervisor, spec) do
          {:ok, _pid} ->
            Logger.info("ServingLoader: #{label} loaded")
            %{state | loaded: MapSet.put(state.loaded, label)}

          {:error, {:already_started, _}} ->
            %{state | loaded: MapSet.put(state.loaded, label)}

          {:error, reason} ->
            Logger.warning("ServingLoader: #{label} failed: #{inspect(reason)}")
            state
        end
      rescue
        e ->
          Logger.warning("ServingLoader: #{label} model load failed: #{Exception.message(e)}")
          state
      end
    end
  end
end
