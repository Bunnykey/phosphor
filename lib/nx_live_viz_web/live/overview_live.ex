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
      <%!-- Hero --%>
      <div class="text-center py-12">
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Real-time ML in Elixir</h1>
        <p class="mt-2 text-gray-500 dark:text-gray-400 max-w-lg mx-auto">
          Interactive machine-learning demos powered by Phoenix LiveView, Nx, and Bumblebee — streaming inference in the browser.
        </p>
      </div>

      <%!-- 2×2 Feature Cards --%>
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 max-w-3xl mx-auto">
        <%!-- Anomaly Detection --%>
        <.link
          navigate={~p"/anomaly"}
          class="border border-gray-200 dark:border-gray-800 rounded-lg p-5 block hover:border-blue-300 dark:hover:border-blue-500 transition-colors"
        >
          <h2 class="text-base font-semibold text-gray-900 dark:text-white">Anomaly Detection</h2>
          <p class="text-sm text-gray-500 dark:text-gray-400 mt-0.5">Autoencoder · Nx</p>
          <svg viewBox="0 0 200 60" class="w-full h-12 mt-3" aria-hidden="true">
            <polyline
              points="0,30 20,20 40,35 60,25 80,30 100,15 120,32 140,28 160,22 180,35 200,30"
              fill="none"
              stroke="#9ca3af"
              stroke-width="1.5"
            />
            <circle cx="100" cy="15" r="3" fill="#ef4444" />
            <circle cx="160" cy="22" r="3" fill="#ef4444" />
          </svg>
          <p class="text-sm text-gray-500 dark:text-gray-400 mt-2">
            Stream sensor data and flag outliers in real time with a trained autoencoder.
          </p>
        </.link>

        <%!-- Image Classification --%>
        <.link
          navigate={~p"/image"}
          class="border border-gray-200 dark:border-gray-800 rounded-lg p-5 block hover:border-blue-300 dark:hover:border-blue-500 transition-colors"
        >
          <h2 class="text-base font-semibold text-gray-900 dark:text-white">Image Classification</h2>
          <p class="text-sm text-gray-500 dark:text-gray-400 mt-0.5">ResNet · Bumblebee</p>
          <svg viewBox="0 0 200 60" class="w-full h-12 mt-3" aria-hidden="true">
            <rect x="0" y="8" width="140" height="10" rx="2" fill="#3b82f6" />
            <rect x="0" y="24" width="90" height="10" rx="2" fill="#9ca3af" />
            <rect x="0" y="40" width="50" height="10" rx="2" fill="#9ca3af" />
          </svg>
          <p class="text-sm text-gray-500 dark:text-gray-400 mt-2">
            Upload or capture an image and see top-k predictions with confidence scores.
          </p>
        </.link>

        <%!-- Sentiment Analysis --%>
        <.link
          navigate={~p"/sentiment"}
          class="border border-gray-200 dark:border-gray-800 rounded-lg p-5 block hover:border-blue-300 dark:hover:border-blue-500 transition-colors"
        >
          <h2 class="text-base font-semibold text-gray-900 dark:text-white">Sentiment Analysis</h2>
          <p class="text-sm text-gray-500 dark:text-gray-400 mt-0.5">BERT · Bumblebee</p>
          <svg viewBox="0 0 200 60" class="w-full h-12 mt-3" aria-hidden="true">
            <rect x="10" y="5" width="55" height="50" rx="2" fill="#22c55e" opacity="0.7" />
            <rect x="73" y="5" width="55" height="50" rx="2" fill="#9ca3af" opacity="0.5" />
            <rect x="136" y="5" width="55" height="50" rx="2" fill="#ef4444" opacity="0.7" />
            <text x="37" y="35" text-anchor="middle" font-size="9" fill="white">pos</text>
            <text x="100" y="35" text-anchor="middle" font-size="9" fill="white">neu</text>
            <text x="163" y="35" text-anchor="middle" font-size="9" fill="white">neg</text>
          </svg>
          <p class="text-sm text-gray-500 dark:text-gray-400 mt-2">
            Type a sentence and watch positive/neutral/negative scores update live.
          </p>
        </.link>

        <%!-- Training Dashboard --%>
        <.link
          navigate={~p"/training"}
          class="border border-gray-200 dark:border-gray-800 rounded-lg p-5 block hover:border-blue-300 dark:hover:border-blue-500 transition-colors"
        >
          <h2 class="text-base font-semibold text-gray-900 dark:text-white">Training Dashboard</h2>
          <p class="text-sm text-gray-500 dark:text-gray-400 mt-0.5">Axon · EXLA</p>
          <svg viewBox="0 0 200 60" class="w-full h-12 mt-3" aria-hidden="true">
            <polyline
              points="0,55 30,45 60,35 90,28 120,22 150,18 180,16 200,15"
              fill="none"
              stroke="#22c55e"
              stroke-width="1.5"
            />
          </svg>
          <p class="text-sm text-gray-500 dark:text-gray-400 mt-2">
            Watch loss and accuracy curves update epoch-by-epoch during Axon training.
          </p>
        </.link>
      </div>
    </Layouts.app>
    """
  end
end
