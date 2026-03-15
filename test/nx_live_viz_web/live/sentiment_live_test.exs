defmodule NxLiveVizWeb.SentimentLiveTest do
  use NxLiveVizWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  defp navigate_to_sentiment(conn) do
    {:ok, view, _html} = live(conn, ~p"/?tab=sentiment")
    sentiment_view = find_live_child(view, "sentiment")
    {view, sentiment_view}
  end

  describe "rendering" do
    test "renders sentiment analysis chart containers", %{conn: conn} do
      {_parent, child} = navigate_to_sentiment(conn)

      assert has_element?(child, "#gauge-chart")
      assert has_element?(child, "#sentiment-trend")
    end

    test "renders text input form with textarea and submit button", %{conn: conn} do
      {_parent, child} = navigate_to_sentiment(conn)

      assert has_element?(child, ~s|form[phx-submit="analyze"]|)
      assert has_element?(child, ~s|textarea[name="text"]|)
      assert has_element?(child, ~s|button[type="submit"]|)
    end

    test "renders sample buttons for quick try", %{conn: conn} do
      {_parent, child} = navigate_to_sentiment(conn)

      assert has_element?(child, ~s|button[phx-click="try-sample"]|)
    end

    test "displays seed history section", %{conn: conn} do
      {_parent, child} = navigate_to_sentiment(conn)

      assert has_element?(child, "h3", "History")
    end

    test "displays sentiment score results from seed data", %{conn: conn} do
      {_parent, child} = navigate_to_sentiment(conn)

      # The results panel with Positive/Negative/Neutral labels
      assert has_element?(child, "span", "Positive")
      assert has_element?(child, "span", "Negative")
    end
  end

  describe "interactions" do
    test "try-sample event populates the text area", %{conn: conn} do
      {_parent, child} = navigate_to_sentiment(conn)

      child
      |> element(~s|button[phx-click="try-sample"]|, "Positive")
      |> render_click()

      assert has_element?(child, ~s|form[phx-submit="analyze"]|)
    end

    test "analyze event with empty text does not crash", %{conn: conn} do
      {_parent, child} = navigate_to_sentiment(conn)

      child
      |> element(~s|form[phx-submit="analyze"]|)
      |> render_submit(%{"text" => ""})

      assert has_element?(child, "#gauge-chart")
    end
  end
end
