defmodule NxLiveVizWeb.PageControllerTest do
  use NxLiveVizWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Phosphor"
  end
end
