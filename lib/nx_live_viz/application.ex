defmodule NxLiveViz.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Pre-train anomaly detector at startup (runs once)
    Task.start(fn -> NxLiveViz.ML.AnomalyDetector.cached_detector(input_size: 20) end)

    children = [
      NxLiveVizWeb.Telemetry,
      {Phoenix.PubSub, name: NxLiveViz.PubSub},

      # State stores
      NxLiveViz.ML.TrainingStore,

      # Data sources
      NxLiveViz.Data.Simulator,
      {NxLiveViz.Data.CryptoAPI, active: false},
      {NxLiveViz.Data.SystemMetrics, active: false},

      # ML Servings (lazy — tolerates network failure at boot)
      NxLiveViz.ML.ServingLoader,

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
