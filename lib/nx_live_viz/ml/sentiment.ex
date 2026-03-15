defmodule NxLiveViz.ML.Sentiment do
  @moduledoc "Multilingual sentiment analysis using Bumblebee + mBERT."

  def serving do
    {:ok, model} = Bumblebee.load_model({:hf, "nlptown/bert-base-multilingual-uncased-sentiment"})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "nlptown/bert-base-multilingual-uncased-sentiment"})

    Bumblebee.Text.text_classification(model, tokenizer,
      compile: [batch_size: 4, sequence_length: 512],
      defn_options: [compiler: EXLA]
    )
  end

  def analyze(text) do
    Nx.Serving.batched_run(NxLiveViz.SentimentServing, text)
  end

  @doc "Analyze sentiment for multiple texts concurrently."
  def analyze_many(texts) when is_list(texts) do
    texts
    |> Task.async_stream(&analyze/1, timeout: 30_000)
    |> Enum.flat_map(fn
      {:ok, result} -> [result]
      {:exit, _reason} -> []
    end)
  end
end
