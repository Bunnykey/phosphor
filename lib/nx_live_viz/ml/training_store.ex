defmodule NxLiveViz.ML.TrainingStore do
  @moduledoc "ETS-based store for persisting training visualization state."

  @table :training_state

  def init do
    if :ets.whereis(@table) == :undefined do
      :ets.new(@table, [:named_table, :protected, :set])
    end

    :ok
  end

  def save(state) do
    try do
      :ets.insert(@table, {:latest, state})
    rescue
      ArgumentError -> :error
    end
  end

  def load do
    try do
      case :ets.lookup(@table, :latest) do
        [{:latest, state}] -> {:ok, state}
        [] -> :error
      end
    rescue
      ArgumentError -> :error
    end
  end

  def clear do
    try do
      :ets.delete(@table, :latest)
    rescue
      ArgumentError -> :ok
    end
  end
end
