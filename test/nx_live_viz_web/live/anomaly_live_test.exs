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

      assert has_element?(child, "span", "Anomalies detected")
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
  end

  describe "interactions" do
    test "change-source event resets data when switching to crypto", %{conn: conn} do
      {_parent, child} = navigate_to_anomaly(conn)

      child
      |> element(~s|select[name="source"]|)
      |> render_change(%{"source" => "crypto"})

      assert has_element?(child, "#anomaly-chart")
    end

    test "change-source event handles sine selection", %{conn: conn} do
      {_parent, child} = navigate_to_anomaly(conn)

      child
      |> element(~s|select[name="source"]|)
      |> render_change(%{"source" => "sine"})

      assert has_element?(child, "#anomaly-chart")
    end
  end
end
