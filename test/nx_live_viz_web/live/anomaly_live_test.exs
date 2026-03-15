defmodule NxLiveVizWeb.AnomalyLiveTest do
  use NxLiveVizWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  defp navigate_to_anomaly(conn) do
    {:ok, view, _html} = live(conn, ~p"/?tab=anomaly")
    anomaly_view = find_live_child(view, "anomaly")
    {view, anomaly_view}
  end

  describe "rendering" do
    test "renders chart and control panel", %{conn: conn} do
      {_parent, child} = navigate_to_anomaly(conn)

      assert has_element?(child, "#anomaly-chart")
      assert has_element?(child, "span", "Control Panel")
    end

    test "renders source selection buttons", %{conn: conn} do
      {_parent, child} = navigate_to_anomaly(conn)

      assert has_element?(child, ~s|button[phx-click="select-source"][phx-value-source="sine"]|)
      assert has_element?(child, ~s|button[phx-click="select-source"][phx-value-source="ecg"]|)
      assert has_element?(child, ~s|button[phx-click="select-source"][phx-value-source="network"]|)
    end

    test "renders parameters section", %{conn: conn} do
      {_parent, child} = navigate_to_anomaly(conn)

      assert has_element?(child, "span", "Window:")
      assert has_element?(child, "span", "Threshold:")
    end

    test "renders start button when not streaming", %{conn: conn} do
      {_parent, child} = navigate_to_anomaly(conn)

      assert has_element?(child, ~s|button[phx-click="start"]|, "Start")
    end
  end

  describe "interactions" do
    test "select-source highlights chosen source", %{conn: conn} do
      {_parent, child} = navigate_to_anomaly(conn)

      child
      |> element(~s|button[phx-value-source="ecg"]|)
      |> render_click()

      html = render(child)
      assert html =~ ~s|phx-value-source="ecg"|
      assert html =~ "bg-indigo-600"
    end

    test "start begins streaming and shows stop button", %{conn: conn} do
      {_parent, child} = navigate_to_anomaly(conn)

      child
      |> element(~s|button[phx-click="start"]|)
      |> render_click()

      assert has_element?(child, ~s|button[phx-click="stop"]|, "Stop")
      assert has_element?(child, "span", "Streaming")
    end

    test "stop returns to idle state", %{conn: conn} do
      {_parent, child} = navigate_to_anomaly(conn)

      child |> element(~s|button[phx-click="start"]|) |> render_click()
      child |> element(~s|button[phx-click="stop"]|) |> render_click()

      assert has_element?(child, ~s|button[phx-click="start"]|, "Start")
    end
  end
end
