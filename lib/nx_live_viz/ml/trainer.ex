defmodule NxLiveViz.ML.Trainer do
  @moduledoc "MNIST trainer with live metrics broadcasting."

  def build_model(dataset \\ :mnist) do
    case dataset do
      :xor ->
        Axon.input("input", shape: {nil, 2})
        |> Axon.dense(4, activation: :relu)
        |> Axon.dense(2, activation: :softmax)

      _ ->
        # MNIST / Fashion-MNIST model (784 -> 128 -> 64 -> 10)
        Axon.input("input", shape: {nil, 784})
        |> Axon.dense(128, activation: :relu)
        |> Axon.dropout(rate: 0.2)
        |> Axon.dense(64, activation: :relu)
        |> Axon.dense(10, activation: :softmax)
    end
  end

  def generate_dummy_data(opts \\ []) do
    dataset = Keyword.get(opts, :dataset, :mnist)
    batch_size = Keyword.get(opts, :batch_size, 32)

    case dataset do
      :mnist -> generate_mnist_data(batch_size)
      :fashion -> generate_fashion_data(batch_size)
      :xor -> generate_xor_data(batch_size)
    end
  end

  defp generate_mnist_data(batch_size) do
    key = Nx.Random.key(42)

    Stream.unfold(key, fn key ->
      {xs, key} = Nx.Random.uniform(key, 0.0, 1.0, shape: {batch_size, 784})
      {labels, key} = Nx.Random.randint(key, 0, 10, shape: {batch_size})
      ys = Nx.equal(Nx.iota({batch_size, 10}, axis: 1), Nx.reshape(labels, {batch_size, 1})) |> Nx.as_type(:f32)
      {{xs, ys}, key}
    end)
  end

  defp generate_fashion_data(batch_size) do
    # Fashion-MNIST-like: bimodal distribution with sharper features
    key = Nx.Random.key(99)

    Stream.unfold(key, fn key ->
      {input, key} = Nx.Random.normal(key, shape: {batch_size, 784})
      input = Nx.abs(input) |> Nx.multiply(0.3)
      {label_indices, key} = Nx.Random.randint(key, 0, 10, shape: {batch_size})
      labels = Nx.equal(Nx.iota({batch_size, 10}, axis: 1), Nx.reshape(label_indices, {batch_size, 1})) |> Nx.as_type(:f32)
      {{input, labels}, key}
    end)
  end

  defp generate_xor_data(batch_size) do
    # XOR pattern: 2D input, 2 classes
    key = Nx.Random.key(77)

    Stream.unfold(key, fn key ->
      {input, key} = Nx.Random.uniform(key, shape: {batch_size, 2})
      # XOR logic: class 1 if (x>0.5 XOR y>0.5)
      x_high = Nx.greater(input[[.., 0]], 0.5)
      y_high = Nx.greater(input[[.., 1]], 0.5)
      xor = Nx.not_equal(x_high, y_high) |> Nx.as_type(:f32)
      labels = Nx.stack([Nx.subtract(1, xor), xor], axis: 1)
      {{input, labels}, key}
    end)
  end

  def train(opts \\ []) do
    topic = Keyword.get(opts, :topic, "training:metrics")
    epochs = Keyword.get(opts, :epochs, 10)
    lr = Keyword.get(opts, :learning_rate, 1.0e-3)
    batch_size = Keyword.get(opts, :batch_size, 32)
    iterations = Keyword.get(opts, :iterations, 50)
    dataset = Keyword.get(opts, :dataset, :mnist)

    model = build_model(dataset)
    data = generate_dummy_data(dataset: dataset, batch_size: batch_size)

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
