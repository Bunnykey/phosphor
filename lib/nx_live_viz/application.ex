defmodule NxLiveViz.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      NxLiveVizWeb.Telemetry,
      {Phoenix.PubSub, name: NxLiveViz.PubSub},

      # Data sources
      NxLiveViz.Data.Simulator,
      {NxLiveViz.Data.CryptoAPI, active: false},

      # ML Servings (each in its own process)
      {Nx.Serving,
       serving: NxLiveViz.ML.ImageClassifier.serving(),
       name: NxLiveViz.ImageServing,
       batch_timeout: 100},
      {Nx.Serving,
       serving: NxLiveViz.ML.Sentiment.serving(),
       name: NxLiveViz.SentimentServing,
       batch_timeout: 100},

      # Web
      NxLiveVizWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: NxLiveViz.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    NxLiveVizWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
