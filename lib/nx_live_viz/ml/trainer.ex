defmodule NxLiveViz.ML.Trainer do
  @moduledoc "MNIST trainer with live metrics broadcasting."

  def build_model do
    Axon.input("input", shape: {nil, 784})
    |> Axon.dense(128, activation: :relu)
    |> Axon.dropout(rate: 0.2)
    |> Axon.dense(64, activation: :relu)
    |> Axon.dense(10, activation: :softmax)
  end

  def generate_dummy_data(batch_size \\ 32) do
    # Synthetic MNIST-like data for demo purposes
    key = Nx.Random.key(42)

    Stream.unfold(key, fn key ->
      {xs, key} = Nx.Random.uniform(key, 0.0, 1.0, shape: {batch_size, 784})
      {labels, key} = Nx.Random.randint(key, 0, 10, shape: {batch_size})
      ys = Nx.equal(Nx.iota({batch_size, 10}, axis: 1), Nx.reshape(labels, {batch_size, 1})) |> Nx.as_type(:f32)
      {{xs, ys}, key}
    end)
  end

  def train(opts \\ []) do
    topic = Keyword.get(opts, :topic, "training:metrics")
    epochs = Keyword.get(opts, :epochs, 10)
    lr = Keyword.get(opts, :learning_rate, 1.0e-3)
    batch_size = Keyword.get(opts, :batch_size, 32)
    iterations = Keyword.get(opts, :iterations, 50)

    model = build_model()
    data = generate_dummy_data(batch_size)

    model
    |> Axon.Loop.trainer(
      :categorical_cross_entropy,
      Polaris.Optimizers.adam(learning_rate: lr)
    )
    |> Axon.Loop.metric(:accuracy)
    |> Axon.Loop.handle_event(:iteration_completed, fn state ->
      metrics = %{
        epoch: state.epoch,
        iteration: state.iteration,
        loss: state.step_state.loss |> Nx.to_number(),
        accuracy: state.metrics["accuracy"] |> Nx.to_number()
      }

      Phoenix.PubSub.broadcast(NxLiveViz.PubSub, topic, {:training_metrics, metrics})

      # Broadcast weight histogram every 10 iterations
      if rem(state.iteration, 10) == 0 do
        first_layer_weights =
          state.step_state.model_state
          |> get_in(["dense_0", "kernel"])

        histogram = compute_histogram(first_layer_weights)
        Phoenix.PubSub.broadcast(NxLiveViz.PubSub, topic, {:weight_histogram, histogram})
      end

      {:continue, state}
    end)
    |> Axon.Loop.run(data, %{}, epochs: epochs, iterations: iterations)
  end

  defp compute_histogram(tensor, num_bins \\ 30) do
    flat = Nx.to_flat_list(tensor)
    min_val = Enum.min(flat)
    max_val = Enum.max(flat)
    range = max_val - min_val
    bin_width = if range == 0, do: 1.0, else: range / num_bins

    # Single-pass O(n) bucket sort
    counts =
      Enum.reduce(flat, :array.new(num_bins, default: 0), fn v, acc ->
        i = trunc((v - min_val) / bin_width) |> max(0) |> min(num_bins - 1)
        :array.set(i, :array.get(i, acc) + 1, acc)
      end)

    bins =
      for i <- 0..(num_bins - 1) do
        Float.round(min_val + (i + 0.5) * bin_width, 4) |> to_string()
      end

    counts_list = for i <- 0..(num_bins - 1), do: :array.get(i, counts)

    %{bins: bins, counts: counts_list}
  end
end
