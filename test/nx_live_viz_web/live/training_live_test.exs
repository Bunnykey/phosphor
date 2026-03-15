defmodule NxLiveVizWeb.TrainingLiveTest do
  use NxLiveVizWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "renders page with charts and form controls", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/training")
    assert has_element?(view, "#loss-chart")
    assert has_element?(view, "#accuracy-chart")
    assert has_element?(view, "#training-params")
    assert has_element?(view, ~s|select[name="dataset"]|)
    assert has_element?(view, ~s|input[name="epochs"]|)
  end

  test "start training shows stop button", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/training")
    view |> element(~s|button[phx-click="start"]|) |> render_click()
    assert has_element?(view, ~s|button[phx-click="stop"]|)
  end

  test "update params changes values", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/training")
    view |> element("#training-params") |> render_change(%{
      "dataset" => "xor", "epochs" => "20", "learning_rate" => "0.005", "batch_size" => "64"
    })
    html = render(view)
    assert html =~ "20"
    assert html =~ "64"
  end

  test "reset restores state", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/training")
    view |> element(~s|button[phx-click="reset"]|) |> render_click()
    assert has_element?(view, "#loss-chart")
  end
end
