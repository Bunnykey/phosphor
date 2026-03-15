defmodule NxLiveViz.ML.SentimentTest do
  use ExUnit.Case, async: true

  alias NxLiveViz.ML.Sentiment

  test "module is defined" do
    assert Code.ensure_loaded?(Sentiment)
  end

  test "module exports serving/0" do
    assert function_exported?(Sentiment, :serving, 0)
  end

  test "module exports analyze/1" do
    assert function_exported?(Sentiment, :analyze, 1)
  end

  @tag :skip
  # serving/0 requires downloading the BERTweet model from HuggingFace.
  # This test is skipped by default to avoid network dependencies in CI.
  test "serving/0 returns an Nx.Serving struct" do
    serving = Sentiment.serving()
    assert %Nx.Serving{} = serving
  end
end
