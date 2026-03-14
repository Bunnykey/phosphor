defmodule NxLiveViz.ML.ImageClassifier do
  @moduledoc "Image classification using Bumblebee + ResNet-50."

  def serving do
    {:ok, model} = Bumblebee.load_model({:hf, "microsoft/resnet-50"})
    {:ok, featurizer} = Bumblebee.load_featurizer({:hf, "microsoft/resnet-50"})

    Bumblebee.Vision.image_classification(model, featurizer,
      top_k: 5,
      compile: [batch_size: 1],
      defn_options: [compiler: EXLA]
    )
  end

  def classify(image_binary) do
    image = StbImage.read_binary!(image_binary)
    Nx.Serving.batched_run(NxLiveViz.ImageServing, image)
  end
end
