defmodule NxLiveViz.ML.Sentiment do
  @moduledoc "Sentiment analysis using Bumblebee + BERTweet."

  def serving do
    {:ok, model} = Bumblebee.load_model({:hf, "finiteautomata/bertweet-base-sentiment-analysis"})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "vinai/bertweet-base"})

    Bumblebee.Text.text_classification(model, tokenizer,
      compile: [batch_size: 4, sequence_length: 128],
      defn_options: [compiler: EXLA]
    )
  end

  def analyze(text) do
    Nx.Serving.batched_run(NxLiveViz.SentimentServing, text)
  end

  @doc "Analyze sentiment for multiple texts concurrently."
  def analyze_many(texts) when is_list(texts) do
    texts
    |> Task.async_stream(fn text -> analyze(text) end, timeout: :infinity)
    |> Enum.map(fn {:ok, result} -> result end)
  end
end
