defmodule NxLiveVizWeb.ImageLiveTest do
  use NxLiveVizWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "renders upload area and chart", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/image")
    assert has_element?(view, "#upload-form")
    assert has_element?(view, "#image-chart")
  end

  test "renders page title", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/image")
    assert html =~ "Image Classification"
    assert html =~ "ResNet-50"
  end

  test "renders seed prediction results", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/image")
    assert html =~ "daisy"
  end

  test "validate event does not crash", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/image")
    view |> element("#upload-form") |> render_change(%{})
    assert has_element?(view, "#upload-form")
  end
end
