defmodule NxLiveViz.ML.TrainingStore do
  @moduledoc "ETS-based store for persisting training visualization state."

  @table :training_state

  def init do
    if :ets.whereis(@table) == :undefined do
      :ets.new(@table, [:named_table, :public, :set])
    end

    :ok
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
