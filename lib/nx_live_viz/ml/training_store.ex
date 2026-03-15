defmodule NxLiveViz.ML.TrainingStore do
  @moduledoc "ETS-based store for persisting training visualization state."
  use GenServer

  @table :training_state

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    table = :ets.new(@table, [:named_table, :protected, :set])
    {:ok, %{table: table}}
  end

  def save(state) do
    GenServer.cast(__MODULE__, {:save, state})
  end

  def load do
    case :ets.lookup(@table, :latest) do
      [{:latest, state}] -> {:ok, state}
      [] -> :error
    end
  rescue
    ArgumentError -> :error
  end

  def clear do
    GenServer.cast(__MODULE__, :clear)
  end

  @impl true
  def handle_cast({:save, state}, s) do
    :ets.insert(@table, {:latest, state})
    {:noreply, s}
  end

  @impl true
  def handle_cast(:clear, s) do
    :ets.delete(@table, :latest)
    {:noreply, s}
  end
end
