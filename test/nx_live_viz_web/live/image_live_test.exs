defmodule NxLiveVizWeb.ImageLiveTest do
  use NxLiveVizWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  defp navigate_to_image(conn) do
    {:ok, view, _html} = live(conn, ~p"/?tab=image")
    image_view = find_live_child(view, "image")
    {view, image_view}
  end

  describe "rendering" do
    test "renders image classification chart container", %{conn: conn} do
      {_parent, child} = navigate_to_image(conn)

      assert has_element?(child, "#image-chart")
    end

    test "renders upload form with drop target", %{conn: conn} do
      {_parent, child} = navigate_to_image(conn)

      assert has_element?(child, ~s|form[phx-change="validate"]|)
    end

    test "displays seed prediction results section", %{conn: conn} do
      {_parent, child} = navigate_to_image(conn)

      # Results heading should be present with seed predictions
      assert has_element?(child, "h3", "Results")
    end

    test "displays seed history section", %{conn: conn} do
      {_parent, child} = navigate_to_image(conn)

      # History heading should be present from seed data
      assert has_element?(child, "h3", "Recent")
    end
  end

  describe "interactions" do
    test "validate event is handled without error", %{conn: conn} do
      {_parent, child} = navigate_to_image(conn)

      child
      |> element(~s|form[phx-change="validate"]|)
      |> render_change(%{})

      assert has_element?(child, "#image-chart")
    end
  end
end
