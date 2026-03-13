defmodule NxLiveVizWeb.ErrorJSONTest do
  use NxLiveVizWeb.ConnCase, async: true

  test "renders 404" do
    assert NxLiveVizWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert NxLiveVizWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
