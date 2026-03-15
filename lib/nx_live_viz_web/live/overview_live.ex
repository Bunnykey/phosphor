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
          <svg viewBox="0 0 200 70" class="w-full h-12 mt-3" aria-hidden="true">
            <%!-- Gauge arc background --%>
            <path d="M 30 55 A 70 70 0 0 1 170 55" fill="none" stroke="#e5e7eb" stroke-width="8" stroke-linecap="round" />
            <%!-- Gauge arc fill (82% positive → mostly green) --%>
            <path d="M 30 55 A 70 70 0 0 1 148 22" fill="none" stroke="#22c55e" stroke-width="8" stroke-linecap="round" />
            <%!-- Needle --%>
            <line x1="100" y1="55" x2="140" y2="28" stroke="#374151" stroke-width="2" stroke-linecap="round" />
            <circle cx="100" cy="55" r="3" fill="#374151" />
            <%!-- Labels --%>
            <text x="22" y="65" font-size="8" fill="#ef4444">neg</text>
            <text x="166" y="65" font-size="8" fill="#22c55e">pos</text>
            <text x="100" y="15" text-anchor="middle" font-size="10" fill="#374151" font-weight="600">82%</text>
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
