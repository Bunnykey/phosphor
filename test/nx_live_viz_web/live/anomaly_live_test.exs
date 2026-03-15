defmodule NxLiveVizWeb.AnomalyLiveTest do
  use NxLiveVizWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  defp navigate_to_anomaly(conn) do
    {:ok, view, _html} = live(conn, ~p"/?tab=anomaly")
    anomaly_view = find_live_child(view, "anomaly")
    {view, anomaly_view}
  end

  describe "rendering" do
    test "renders anomaly detection chart container", %{conn: conn} do
      {_parent, child} = navigate_to_anomaly(conn)

      assert has_element?(child, "#anomaly-chart")
    end

    test "displays anomaly count text", %{conn: conn} do
      {_parent, child} = navigate_to_anomaly(conn)

      assert has_element?(child, "span", "Anomalies")
    end

    test "renders data source selector with options", %{conn: conn} do
      {_parent, child} = navigate_to_anomaly(conn)

      assert has_element?(child, ~s|select[name="source"]|)
      assert has_element?(child, ~s|option[value="sine"]|)
      assert has_element?(child, ~s|option[value="ecg"]|)
      assert has_element?(child, ~s|option[value="network"]|)
      assert has_element?(child, ~s|option[value="crypto"]|)
      assert has_element?(child, ~s|option[value="system"]|)
    end

    test "renders info bar with hyperparameters", %{conn: conn} do
      {_parent, child} = navigate_to_anomaly(conn)

      assert has_element?(child, "span", "Sine Wave")
      assert has_element?(child, "span", "Window: 20")
      assert has_element?(child, "span", "Threshold: 0.5")
    end

    test "renders start button when not streaming", %{conn: conn} do
      {_parent, child} = navigate_to_anomaly(conn)

      assert has_element?(child, ~s|button[phx-click="start"]|, "Start")
    end
  end

  describe "interactions" do
    test "start button begins streaming", %{conn: conn} do
      {_parent, child} = navigate_to_anomaly(conn)

      child
      |> element(~s|button[phx-click="start"]|)
      |> render_click()

      assert has_element?(child, ~s|button[phx-click="stop"]|, "Stop")
      assert has_element?(child, "span", "Live")
    end

    test "stop button stops streaming", %{conn: conn} do
      {_parent, child} = navigate_to_anomaly(conn)

      child
      |> element(~s|button[phx-click="start"]|)
      |> render_click()

      child
      |> element(~s|button[phx-click="stop"]|)
      |> render_click()

      assert has_element?(child, ~s|button[phx-click="start"]|, "Start")
    end

    test "change-source event updates source label", %{conn: conn} do
      {_parent, child} = navigate_to_anomaly(conn)

      child
      |> element(~s|select[name="source"]|)
      |> render_change(%{"source" => "ecg"})

      assert has_element?(child, "span", "ECG Heartbeat")
    end
  end
end
