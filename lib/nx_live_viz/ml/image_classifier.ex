defmodule NxLiveViz.ML.ImageClassifier do
  @moduledoc "Image classification using Bumblebee + ResNet-50."

  @spec serving() :: Nx.Serving.t()
  def serving do
    {:ok, model} = Bumblebee.load_model({:hf, "microsoft/resnet-50"})
    {:ok, featurizer} = Bumblebee.load_featurizer({:hf, "microsoft/resnet-50"})

    Bumblebee.Vision.image_classification(model, featurizer,
      top_k: 5,
      compile: [batch_size: 4],
      defn_options: [compiler: EXLA]
    )
  end

  @spec classify(binary()) :: map()
  def classify(image_binary) do
    image = StbImage.read_binary!(image_binary)
    Nx.Serving.batched_run(NxLiveViz.ImageServing, image)
  end

  @doc "Classify multiple images concurrently, leveraging Nx.Serving's internal batching."
  @spec classify_many([binary()]) :: [map()]
  def classify_many(image_binaries) when is_list(image_binaries) do
    image_binaries
    |> Task.async_stream(&classify/1, timeout: 30_000)
    |> Enum.flat_map(fn
      {:ok, result} -> [result]
      {:exit, _reason} -> []
    end)
  end
end
