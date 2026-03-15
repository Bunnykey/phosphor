defmodule NxLiveVizWeb.OverviewLive do
  use NxLiveVizWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :current_path, "/")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path}>
      <div class="text-center py-12">
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Real-time ML in Elixir</h1>
        <p class="mt-2 text-gray-500 dark:text-gray-400">Overview placeholder — cards coming next</p>
      </div>
    </Layouts.app>
    """
  end
end
