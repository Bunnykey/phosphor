defmodule NxLiveViz.ML.Sentiment do
  @moduledoc "Sentiment analysis using Bumblebee + BERTweet."

  def serving do
    {:ok, model} = Bumblebee.load_model({:hf, "finiteautomata/bertweet-base-sentiment-analysis"})
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, "vinai/bertweet-base"})

    Bumblebee.Text.text_classification(model, tokenizer,
      compile: [batch_size: 1, sequence_length: 128],
      defn_options: [compiler: EXLA]
    )
  end

  def analyze(text) do
    Nx.Serving.batched_run(NxLiveViz.SentimentServing, text)
  end
end
