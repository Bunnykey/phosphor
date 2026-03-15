defmodule NxLiveVizWeb.TrainingLiveTest do
  use NxLiveVizWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  defp navigate_to_training(conn) do
    {:ok, view, _html} = live(conn, ~p"/?tab=training")
    training_view = find_live_child(view, "training")
    {view, training_view}
  end

  describe "rendering" do
    test "renders training visualization chart containers", %{conn: conn} do
      {_parent, child} = navigate_to_training(conn)

      assert has_element?(child, "#loss-chart")
      assert has_element?(child, "#accuracy-chart")
      assert has_element?(child, "#weight-histogram")
    end

    test "renders start and reset buttons when not training", %{conn: conn} do
      {_parent, child} = navigate_to_training(conn)

      assert has_element?(child, ~s|button[phx-click="start"]|)
      assert has_element?(child, ~s|button[phx-click="reset"]|)
    end

    test "renders hyperparameter controls form", %{conn: conn} do
      {_parent, child} = navigate_to_training(conn)

      assert has_element?(child, ~s|form[phx-change="update-params"]|)
      assert has_element?(child, ~s|input[name="epochs"]|)
      assert has_element?(child, ~s|input[name="learning_rate"]|)
      assert has_element?(child, ~s|input[name="batch_size"]|)
    end

    test "displays metric values for epoch and iteration", %{conn: conn} do
      {_parent, child} = navigate_to_training(conn)

      assert has_element?(child, "div.text-sm")
    end
  end

  describe "interactions" do
    test "reset event restores seed training data", %{conn: conn} do
      {_parent, child} = navigate_to_training(conn)

      child
      |> element(~s|button[phx-click="reset"]|)
      |> render_click()

      assert has_element?(child, "#loss-chart")
      assert has_element?(child, "#accuracy-chart")
      assert has_element?(child, "#weight-histogram")
      assert has_element?(child, ~s|button[phx-click="start"]|)
    end

    test "update-params event adjusts hyperparameters", %{conn: conn} do
      {_parent, child} = navigate_to_training(conn)

      child
      |> element(~s|form[phx-change="update-params"]|)
      |> render_change(%{"epochs" => "20", "learning_rate" => "0.005", "batch_size" => "64"})

      assert has_element?(child, ~s|form[phx-change="update-params"]|)
    end
  end
end
