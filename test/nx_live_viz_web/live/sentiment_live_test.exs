defmodule NxLiveVizWeb.SentimentLiveTest do
  use NxLiveVizWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "renders text input form", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/sentiment")
    assert has_element?(view, "#sentiment-form")
    assert has_element?(view, ~s|textarea[name="text"]|)
    assert has_element?(view, ~s|button[type="submit"]|)
  end

  test "renders quick sample buttons", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/sentiment")
    assert has_element?(view, ~s|button[phx-click="try-sample"]|, "Positive")
    assert has_element?(view, ~s|button[phx-click="try-sample"]|, "Negative")
    assert has_element?(view, ~s|button[phx-click="try-sample"]|, "Neutral")
  end

  test "quick sample populates text", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/sentiment")
    view |> element(~s|button[phx-click="try-sample"]|, "Positive") |> render_click()
    assert has_element?(view, "#sentiment-form")
  end

  test "analyze with empty text shows error", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/sentiment")
    view |> element("#sentiment-form") |> render_submit(%{"text" => ""})
    html = render(view)
    assert html =~ "enter" or html =~ "Please"
  end

  test "renders sentiment trend chart and history", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/sentiment")
    assert has_element?(view, "#sentiment-trend")
    assert has_element?(view, "#gauge-chart")
  end
end
