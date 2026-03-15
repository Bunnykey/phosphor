defmodule NxLiveVizWeb.DashboardLiveTest do
  use NxLiveVizWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "renders dashboard" do
    test "mounts with default anomaly tab active", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, "header")
      assert has_element?(view, "nav")
      # The anomaly child LiveView should be rendered by default
      assert has_element?(view, "#anomaly")
    end

    test "shows all tab navigation links", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(view, ~s|a[href="/?tab=anomaly"]|)
      assert has_element?(view, ~s|a[href="/?tab=image"]|)
      assert has_element?(view, ~s|a[href="/?tab=sentiment"]|)
      assert has_element?(view, ~s|a[href="/?tab=training"]|)
    end
  end

  describe "tab navigation" do
    test "clicking image tab renders image child LiveView", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> element(~s|a[href="/?tab=image"]|)
      |> render_click()

      assert has_element?(view, "#image")
    end

    test "clicking sentiment tab renders sentiment child LiveView", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> element(~s|a[href="/?tab=sentiment"]|)
      |> render_click()

      assert has_element?(view, "#sentiment")
    end

    test "clicking training tab renders training child LiveView", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view
      |> element(~s|a[href="/?tab=training"]|)
      |> render_click()

      assert has_element?(view, "#training")
    end

    test "URL query parameter selects the correct tab", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?tab=training")

      assert has_element?(view, "#training")
      refute has_element?(view, "#anomaly")
    end

    test "invalid tab param falls back to anomaly", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/?tab=invalid")

      assert has_element?(view, "#anomaly")
    end
  end
end
