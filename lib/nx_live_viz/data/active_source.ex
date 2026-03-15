defmodule NxLiveViz.Data.ActiveSource do
  @moduledoc "Behaviour for activate/deactivate GenServer data sources."

  @callback collect(state :: map()) :: map()
  @callback source_interval() :: pos_integer()
  @callback init_state(keyword()) :: map()

  defmacro __using__(_opts) do
    quote do
      use GenServer
      @behaviour NxLiveViz.Data.ActiveSource

      def start_link(opts \\ []) do
        name = Keyword.get(opts, :name, __MODULE__)
        GenServer.start_link(__MODULE__, opts, name: name)
      end

      @spec activate(GenServer.server()) :: :ok
      def activate(server \\ __MODULE__), do: GenServer.cast(server, :activate)

      @spec deactivate(GenServer.server()) :: :ok
      def deactivate(server \\ __MODULE__), do: GenServer.cast(server, :deactivate)

      @impl GenServer
      def init(opts) do
        active = Keyword.get(opts, :active, false)
        if active, do: schedule_tick(source_interval())
        {:ok, init_state(opts)}
      end

      @impl GenServer
      def handle_cast(:activate, %{active: true} = state), do: {:noreply, state}

      def handle_cast(:activate, state) do
        schedule_tick(source_interval())
        {:noreply, %{state | active: true}}
      end

      def handle_cast(:deactivate, state), do: {:noreply, %{state | active: false}}

      @impl GenServer
      def handle_info(:tick, %{active: false} = state), do: {:noreply, state}

      def handle_info(:tick, state) do
        state = collect(state)
        schedule_tick(source_interval())
        {:noreply, state}
      end

      defp schedule_tick(interval), do: Process.send_after(self(), :tick, interval)

      defoverridable init: 1
    end
  end
end
