defmodule NxLiveVizWeb.TrainingLive do
  use NxLiveVizWeb, :live_view

  @impl true
  def mount(_params, _session, socket), do: {:ok, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="text-gray-400">Training Visualization — coming soon</div>
    """
  end
end
