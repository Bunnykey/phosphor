defmodule NxLiveViz.ML.ImageClassifierTest do
  use ExUnit.Case, async: true

  alias NxLiveViz.ML.ImageClassifier

  test "module is defined" do
    assert Code.ensure_loaded?(ImageClassifier)
  end

  test "module exports serving/0" do
    assert function_exported?(ImageClassifier, :serving, 0)
  end

  test "module exports classify/1" do
    assert function_exported?(ImageClassifier, :classify, 1)
  end

  @tag :skip
  # serving/0 requires downloading the ResNet-50 model from HuggingFace.
  # This test is skipped by default to avoid network dependencies in CI.
  test "serving/0 returns an Nx.Serving struct" do
    serving = ImageClassifier.serving()
    assert %Nx.Serving{} = serving
  end
end
