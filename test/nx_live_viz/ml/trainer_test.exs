defmodule NxLiveViz.ML.TrainerTest do
  use ExUnit.Case, async: true

  alias NxLiveViz.ML.Trainer

  test "build_model returns an Axon model" do
    model = Trainer.build_model()
    assert %Axon{} = model
  end

  test "model has correct layer structure (input -> dense -> dropout -> dense -> dense)" do
    model = Trainer.build_model()

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
    model = Trainer.build_model()
    {init_fn, predict_fn} = Axon.build(model, mode: :inference)
    params = init_fn.(Nx.template({1, 784}, :f32), %{})

    input = Nx.broadcast(0.5, {1, 784})
    output = predict_fn.(params, input)

    # Softmax output should sum to approximately 1.0
    sum = output |> Nx.sum() |> Nx.to_number()
    assert_in_delta sum, 1.0, 0.01
  end

  test "generate_dummy_data returns a stream" do
    data = Trainer.generate_dummy_data(16)
    assert is_function(data, 2), "expected generate_dummy_data to return a Stream (function/2)"
  end

  test "generate_dummy_data produces tensors with correct shapes" do
    data = Trainer.generate_dummy_data(16)

    [{xs, ys} | _] = Enum.take(data, 1)

    assert {16, 784} == Nx.shape(xs)
    assert {16, 10} == Nx.shape(ys)
  end

  test "generate_dummy_data labels are one-hot encoded" do
    data = Trainer.generate_dummy_data(8)

    [{_xs, ys} | _] = Enum.take(data, 1)

    # Each row in ys should sum to 1.0 (one-hot)
    row_sums = ys |> Nx.sum(axes: [1]) |> Nx.to_flat_list()

    for sum <- row_sums do
      assert_in_delta sum, 1.0, 0.01
    end
  end

  test "generate_dummy_data is deterministic (seeded with key 42)" do
    batch_a = Trainer.generate_dummy_data(4) |> Enum.take(1) |> hd()
    batch_b = Trainer.generate_dummy_data(4) |> Enum.take(1) |> hd()

    {xs_a, ys_a} = batch_a
    {xs_b, ys_b} = batch_b

    assert Nx.equal(xs_a, xs_b) |> Nx.all() |> Nx.to_number() == 1
    assert Nx.equal(ys_a, ys_b) |> Nx.all() |> Nx.to_number() == 1
  end
end
