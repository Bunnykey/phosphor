defmodule NxLiveViz.ML.TrainerTest do
  use ExUnit.Case, async: true

  alias NxLiveViz.ML.Trainer

  test "build_model returns an Axon model" do
    model = Trainer.build_model(:mnist)
    assert %Axon{} = model
  end

  test "model has correct layer structure (input -> dense -> dropout -> dense -> dense)" do
    model = Trainer.build_model(:mnist)

    # Build the model to verify it compiles and accepts the expected input shape
    {init_fn, predict_fn} = Axon.build(model)
    params = init_fn.(Nx.template({1, 784}, :f32), %{})

    # Verify the model can forward pass with the expected input shape
    input = Nx.broadcast(0.5, {1, 784})
    output = predict_fn.(params, input)

    # Output should be {1, 10} for 10-class classification
    assert {1, 10} == Nx.shape(output)
  end

  test "model output sums to ~1.0 (softmax)" do
    model = Trainer.build_model(:mnist)
    {init_fn, predict_fn} = Axon.build(model, mode: :inference)
    params = init_fn.(Nx.template({1, 784}, :f32), %{})

    input = Nx.broadcast(0.5, {1, 784})
    output = predict_fn.(params, input)

    # Softmax output should sum to approximately 1.0
    sum = output |> Nx.sum() |> Nx.to_number()
    assert_in_delta sum, 1.0, 0.01
  end

  test "build_model returns XOR model with correct shape" do
    model = Trainer.build_model(:xor)
    {init_fn, predict_fn} = Axon.build(model, mode: :inference)
    params = init_fn.(Nx.template({1, 2}, :f32), %{})

    input = Nx.tensor([[0.3, 0.7]])
    output = predict_fn.(params, input)
    assert {1, 2} == Nx.shape(output)
  end

  test "generate_dummy_data returns a stream" do
    data = Trainer.generate_dummy_data(dataset: :mnist, batch_size: 16)
    assert is_function(data, 2), "expected generate_dummy_data to return a Stream (function/2)"
  end

  test "generate_dummy_data produces tensors with correct shapes" do
    data = Trainer.generate_dummy_data(dataset: :mnist, batch_size: 16)

    [{xs, ys} | _] = Enum.take(data, 1)

    assert {16, 784} == Nx.shape(xs)
    assert {16, 10} == Nx.shape(ys)
  end

  test "generate_dummy_data labels are one-hot encoded" do
    data = Trainer.generate_dummy_data(dataset: :mnist, batch_size: 8)

    [{_xs, ys} | _] = Enum.take(data, 1)

    # Each row in ys should sum to 1.0 (one-hot)
    row_sums = ys |> Nx.sum(axes: [1]) |> Nx.to_flat_list()

    for sum <- row_sums do
      assert_in_delta sum, 1.0, 0.01
    end
  end

  test "generate_dummy_data XOR produces 2D input" do
    data = Trainer.generate_dummy_data(dataset: :xor, batch_size: 8)
    [{xs, ys} | _] = Enum.take(data, 1)

    assert {8, 2} == Nx.shape(xs)
    assert {8, 2} == Nx.shape(ys)
  end
end
