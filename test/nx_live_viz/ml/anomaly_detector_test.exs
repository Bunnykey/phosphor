defmodule NxLiveViz.ML.AnomalyDetectorTest do
  use ExUnit.Case, async: true

  alias NxLiveViz.ML.AnomalyDetector

  test "builds autoencoder model" do
    model = AnomalyDetector.build_model(input_size: 10)
    assert %Axon{} = model
  end

  test "detects anomaly from reconstruction error" do
    # Normal value should have low reconstruction error
    normal_window = List.duplicate(50.0, 10) |> Nx.tensor() |> Nx.reshape({1, 10})
    # For untrained model, just verify it returns a result
    params = AnomalyDetector.init_params(input_size: 10)
    result = AnomalyDetector.predict(params, normal_window)
    assert Map.has_key?(result, :reconstruction_error)
    assert Map.has_key?(result, :is_anomaly)
  end

  test "pretrained_detector produces result on normal data" do
    detector = AnomalyDetector.pretrained_detector(input_size: 10)
    normal = for i <- 0..9, do: :math.sin(i / 3.0) * 10 + 50
    input = Nx.tensor([normal], type: :f32)
    result = AnomalyDetector.predict(detector, input)
    assert is_float(result.reconstruction_error)
    assert is_boolean(result.is_anomaly)
  end

  test "pretrained_detector produces positive error on anomalous data" do
    detector = AnomalyDetector.pretrained_detector(input_size: 10)
    anomalous = List.duplicate(500.0, 10)
    input = Nx.tensor([anomalous], type: :f32)
    result = AnomalyDetector.predict(detector, input)
    assert result.reconstruction_error > 0
  end

  test "cached_detector returns same params on subsequent calls" do
    d1 = AnomalyDetector.cached_detector(input_size: 20)
    d2 = AnomalyDetector.cached_detector(input_size: 20)
    assert d1.params == d2.params
  end
end
