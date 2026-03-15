defmodule NxLiveVizWeb.OverviewLiveTest do
  use NxLiveVizWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "renders hero section", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/")
    assert html =~ "Real-time ML in Elixir"
  end

  test "renders 4 feature cards with navigation links", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    assert has_element?(view, ~s|a[href="/anomaly"]|)
    assert has_element?(view, ~s|a[href="/image"]|)
    assert has_element?(view, ~s|a[href="/sentiment"]|)
    assert has_element?(view, ~s|a[href="/training"]|)
  end

  test "renders layout nav and footer", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")
    assert html =~ "Phosphor"
    assert html =~ "Phoenix LiveView"
    assert has_element?(view, ~s|a[href="/anomaly"]|, "Anomaly")
  end

  test "anomaly card shows title and description", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    assert has_element?(view, ~s|a[href="/anomaly"]|, "Anomaly Detection")
  end

  test "training card shows title", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    assert has_element?(view, ~s|a[href="/training"]|, "Training")
  end
end
