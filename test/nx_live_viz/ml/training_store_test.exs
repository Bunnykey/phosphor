defmodule NxLiveViz.ML.TrainingStoreTest do
  use ExUnit.Case

  alias NxLiveViz.ML.TrainingStore

  setup do
    TrainingStore.clear()
    _ = :sys.get_state(TrainingStore)
    :ok
  end

  test "save/1 and load/0 round-trip training state" do
    state = %{
      loss_history: [0.5, 0.3, 0.1],
      accuracy_history: [0.6, 0.8, 0.95],
      histogram: %{bins: ["0.1", "0.2"], counts: [10, 20]},
      current_epoch: 3,
      current_iteration: 50,
      current_loss: 0.1,
      current_accuracy: 0.95,
      status: :completed
    }

    TrainingStore.save(state)
    _ = :sys.get_state(TrainingStore)

    assert {:ok, loaded} = TrainingStore.load()
    assert loaded.loss_history == [0.5, 0.3, 0.1]
    assert loaded.current_epoch == 3
    assert loaded.status == :completed
  end

  test "load/0 returns :error when empty" do
    assert :error == TrainingStore.load()
  end

  test "clear/0 removes persisted state" do
    TrainingStore.save(%{
      loss_history: [1.0],
      accuracy_history: [0.5],
      histogram: nil,
      current_epoch: 1,
      current_iteration: 10,
      current_loss: 1.0,
      current_accuracy: 0.5,
      status: :training
    })

    _ = :sys.get_state(TrainingStore)
    assert {:ok, _} = TrainingStore.load()

    TrainingStore.clear()
    _ = :sys.get_state(TrainingStore)
    assert :error == TrainingStore.load()
  end

  test "save/1 overwrites previous state" do
    TrainingStore.save(%{
      loss_history: [1.0],
      accuracy_history: [0.5],
      histogram: nil,
      current_epoch: 1,
      current_iteration: 10,
      current_loss: 1.0,
      current_accuracy: 0.5,
      status: :training
    })

    _ = :sys.get_state(TrainingStore)

    TrainingStore.save(%{
      loss_history: [0.5, 0.1],
      accuracy_history: [0.8, 0.95],
      histogram: nil,
      current_epoch: 5,
      current_iteration: 50,
      current_loss: 0.1,
      current_accuracy: 0.95,
      status: :completed
    })

    _ = :sys.get_state(TrainingStore)

    assert {:ok, loaded} = TrainingStore.load()
    assert loaded.current_epoch == 5
    assert loaded.loss_history == [0.5, 0.1]
  end
end
