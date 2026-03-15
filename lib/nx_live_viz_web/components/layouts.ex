defmodule NxLiveVizWeb.Layouts do
  @moduledoc """
  Shared layout components — header, navigation, footer, flash, theme toggle.
  """
  use NxLiveVizWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true
  attr :current_path, :string, default: "/"
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div class="min-h-screen bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">
      <header class="border-b border-gray-200 dark:border-gray-800">
        <div class="max-w-5xl mx-auto px-6 py-3 flex items-center justify-between">
          <div class="flex items-center gap-6">
            <.link navigate={~p"/"} class="text-base font-semibold text-gray-900 dark:text-white hover:text-gray-600 dark:hover:text-gray-300">
              Phosphor
            </.link>
            <nav class="hidden sm:flex gap-4 text-sm">
              <.nav_link href={~p"/"} label="Overview" current={@current_path} />
              <.nav_link href={~p"/anomaly"} label="Anomaly" current={@current_path} />
              <.nav_link href={~p"/image"} label="Image" current={@current_path} />
              <.nav_link href={~p"/sentiment"} label="Sentiment" current={@current_path} />
              <.nav_link href={~p"/training"} label="Training" current={@current_path} />
            </nav>
          </div>
          <.theme_toggle />
        </div>
      </header>

      <main class="max-w-5xl mx-auto px-6 py-6">
        {render_slot(@inner_block)}
      </main>

      <.flash_group flash={@flash} />

      <footer class="border-t border-gray-200 dark:border-gray-800 mt-12">
        <div class="max-w-5xl mx-auto px-6 py-4 text-center text-xs text-gray-400 dark:text-gray-500">
          Built with Phoenix LiveView · Nx · Axon · Bumblebee · EXLA
        </div>
      </footer>
    </div>
    """
  end

  attr :href, :string, required: true
  attr :label, :string, required: true
  attr :current, :string, required: true

  defp nav_link(assigns) do
    active =
      (assigns.href == "/" and assigns.current == "/") or
        (assigns.href != "/" and String.starts_with?(assigns.current, assigns.href))

    assigns = assign(assigns, :active, active)

    ~H"""
    <.link navigate={@href} class={[
      "transition-colors",
      if(@active,
        do: "text-blue-600 dark:text-blue-400 font-medium",
        else: "text-gray-500 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-200"
      )
    ]}>
      {@label}
    </.link>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title="We can't find the internet"
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title="Something went wrong!"
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="relative flex flex-row items-center border-2 border-gray-200 dark:border-gray-700 bg-gray-100 dark:bg-gray-800 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-700 left-0 [.light_&]:left-1/3 [.dark_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
