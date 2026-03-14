defmodule NxLiveViz.ML.AnomalyDetector do
  @moduledoc "Autoencoder-based anomaly detector using Axon."

  @default_input_size 20
  @threshold 0.5

  def build_model(opts \\ []) do
    input_size = Keyword.get(opts, :input_size, @default_input_size)

    Axon.input("input", shape: {nil, input_size})
    |> Axon.dense(input_size |> div(2), activation: :relu)
    |> Axon.dense(input_size |> div(4), activation: :relu)
    |> Axon.dense(input_size |> div(2), activation: :relu)
    |> Axon.dense(input_size)
  end

  def init_params(opts \\ []) do
    input_size = Keyword.get(opts, :input_size, @default_input_size)
    model = build_model(opts)
    template = Nx.template({1, input_size}, :f32)
    {init_fn, _} = Axon.build(model)
    params = init_fn.(template, %{})
    %{params: params, model: model, input_size: input_size}
  end

  def predict(%{params: params, model: model}, input) do
    {_init_fn, predict_fn} = Axon.build(model)
    output = predict_fn.(params, input)

    reconstruction_error =
      Nx.subtract(input, output)
      |> Nx.pow(2)
      |> Nx.mean()
      |> Nx.to_number()

    %{
      reconstruction_error: reconstruction_error,
      is_anomaly: reconstruction_error > @threshold,
      reconstructed: output
    }
  end

  def train(state, data, opts \\ []) do
    epochs = Keyword.get(opts, :epochs, 10)

    model = state.model

    trained_state =
      model
      |> Axon.Loop.trainer(:mean_squared_error, Polaris.Optimizers.adam(learning_rate: 1.0e-3))
      |> Axon.Loop.run(data, state.params, epochs: epochs)

    %{state | params: trained_state}
  end
end
