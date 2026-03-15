defmodule NxLiveVizWeb.OverviewLiveTest do
  use NxLiveVizWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "layout renders navigation links", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")
    assert html =~ "Phosphor"
    assert has_element?(view, ~s|a[href="/"]|, "Overview")
    assert has_element?(view, ~s|a[href="/anomaly"]|, "Anomaly")
    assert has_element?(view, ~s|a[href="/image"]|, "Image")
    assert has_element?(view, ~s|a[href="/sentiment"]|, "Sentiment")
    assert has_element?(view, ~s|a[href="/training"]|, "Training")
  end

  test "layout renders footer with tech stack", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")
    assert html =~ "Phoenix LiveView"
    assert html =~ "Bumblebee"
  end

  test "renders hero placeholder", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")
    assert html =~ "Real-time ML in Elixir"
  end
end
