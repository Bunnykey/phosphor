defmodule NxLiveVizWeb.PageController do
  use NxLiveVizWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
