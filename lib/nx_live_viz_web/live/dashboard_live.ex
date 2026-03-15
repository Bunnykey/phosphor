defmodule NxLiveVizWeb.DashboardLive do
  use NxLiveVizWeb, :live_view

  @tabs ~w(anomaly image sentiment training)a
  @tab_map %{"anomaly" => :anomaly, "image" => :image, "sentiment" => :sentiment, "training" => :training}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, active_tab: :anomaly)}
  end

  @impl true
  def handle_params(%{"tab" => tab}, _uri, socket) when is_map_key(@tab_map, tab) do
    {:noreply, assign(socket, active_tab: @tab_map[tab])}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, active_tab: :anomaly)}
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :tabs, @tabs)

    ~H"""
    <div class="min-h-screen bg-gray-50 dark:bg-gray-950 text-gray-900 dark:text-white">
      <header class="border-b border-gray-200 dark:border-gray-800 px-6 py-4 flex items-center gap-3">
        <div class="w-8 h-8 rounded-lg bg-indigo-600 dark:bg-indigo-500 flex items-center justify-center">
          <span class="text-white font-bold text-sm">P</span>
        </div>
        <div>
          <h1 class="text-xl font-semibold tracking-tight text-gray-900 dark:text-white">Phosphor</h1>
          <p class="text-xs text-gray-500 dark:text-gray-400">Real-time ML Visualization Dashboard</p>
        </div>
      </header>

      <nav class="flex gap-1 px-6 pt-4">
        <.tab_button
          :for={tab <- @tabs}
          tab={tab}
          active={@active_tab == tab}
          patch={~p"/?tab=#{tab}"}
        />
      </nav>

      <main class="p-6">
        <%= case @active_tab do %>
          <% :anomaly -> %>
            {live_render(@socket, NxLiveVizWeb.AnomalyLive, id: "anomaly")}
          <% :image -> %>
            {live_render(@socket, NxLiveVizWeb.ImageLive, id: "image")}
          <% :sentiment -> %>
            {live_render(@socket, NxLiveVizWeb.SentimentLive, id: "sentiment")}
          <% :training -> %>
            {live_render(@socket, NxLiveVizWeb.TrainingLive, id: "training")}
        <% end %>
      </main>
    </div>
    """
  end

  attr :tab, :atom, required: true
  attr :active, :boolean, required: true
  attr :patch, :string, required: true

  defp tab_button(assigns) do
    labels = %{
      anomaly: "Anomaly Detection",
      image: "Image Classification",
      sentiment: "Sentiment Analysis",
      training: "Training Viz"
    }

    assigns = assign(assigns, :label, labels[assigns.tab])

    ~H"""
    <.link
      patch={@patch}
      class={[
        "px-4 py-2 rounded-t-lg text-sm font-medium transition-colors",
        if(@active,
          do: "bg-gray-100 dark:bg-gray-800 text-indigo-600 dark:text-indigo-400 border-b-2 border-indigo-600 dark:border-indigo-400",
          else: "text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-900"
        )
      ]}
    >
      {@label}
    </.link>
    """
  end
end
