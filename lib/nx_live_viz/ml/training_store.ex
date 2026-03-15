defmodule NxLiveViz.ML.TrainingStore do
  @moduledoc "ETS-based store for persisting training visualization state."
  use GenServer

  @table :training_state

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    table = :ets.new(@table, [:named_table, :public, :set])
    {:ok, %{table: table}}
  end

  def save(state) do
    :ets.insert(@table, {:latest, state})
  end

  def load do
    case :ets.lookup(@table, :latest) do
      [{:latest, state}] -> {:ok, state}
      [] -> :error
    end
  end

  def clear do
    :ets.delete(@table, :latest)
  end
end
