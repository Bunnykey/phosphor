defmodule NxLiveVizWeb.AnomalyLiveTest do
  use NxLiveVizWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "renders page with chart and form controls", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/anomaly")
    assert has_element?(view, "#anomaly-chart")
    assert has_element?(view, "#anomaly-params")
    assert has_element?(view, ~s|select[name="source"]|)
    assert has_element?(view, ~s|input[name="window"]|)
    assert has_element?(view, ~s|input[name="threshold"]|)
  end

  test "renders start button when not streaming", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/anomaly")
    assert has_element?(view, ~s|button[phx-click="start"]|, "Start")
    refute has_element?(view, ~s|button[phx-click="stop"]|)
  end

  test "changing source via form works", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/anomaly")
    view |> element("#anomaly-params") |> render_change(%{"source" => "ecg", "window" => "20", "threshold" => "0.5"})
    html = render(view)
    assert html =~ "ecg"
  end

  test "start and stop streaming", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/anomaly")
    view |> element(~s|button[phx-click="start"]|) |> render_click()
    assert has_element?(view, ~s|button[phx-click="stop"]|)

    view |> element(~s|button[phx-click="stop"]|) |> render_click()
    assert has_element?(view, ~s|button[phx-click="start"]|)
  end
end
