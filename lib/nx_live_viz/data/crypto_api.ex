defmodule NxLiveViz.Data.CryptoAPI do
  @moduledoc "Fetches cryptocurrency price data as time series."

  use GenServer

  require Logger

  @interval 2_000
  @api_url "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd"

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    active = Keyword.get(opts, :active, false)
    if active, do: schedule_fetch()
    {:ok, %{active: active, last_value: nil}}
  end

  def activate(server \\ __MODULE__) do
    GenServer.cast(server, :activate)
  end

  def deactivate(server \\ __MODULE__) do
    GenServer.cast(server, :deactivate)
  end

  @impl true
  def handle_cast(:activate, %{active: true} = state) do
    {:noreply, state}
  end

  def handle_cast(:activate, state) do
    schedule_fetch()
    {:noreply, %{state | active: true}}
  end

  def handle_cast(:deactivate, state) do
    {:noreply, %{state | active: false}}
  end

  @impl true
  def handle_info(:fetch, %{active: false} = state), do: {:noreply, state}

  def handle_info(:fetch, state) do
    case fetch_price() do
      {:ok, price} ->
        point = %{
          value: price * 1.0,
          timestamp: DateTime.utc_now(),
          anomaly: false
        }

        NxLiveViz.broadcast_sensor_data(point)
        schedule_fetch()
        {:noreply, %{state | last_value: price}}

      {:error, reason} ->
        Logger.warning("CryptoAPI fetch failed: #{inspect(reason)}")

        if state.last_value do
          point = %{
            value: state.last_value * 1.0,
            timestamp: DateTime.utc_now(),
            anomaly: false
          }

          NxLiveViz.broadcast_sensor_data(point)
        end

        schedule_fetch()
        {:noreply, state}
    end
  end

  defp fetch_price do
    case Req.get(@api_url) do
      {:ok, %Req.Response{status: 200, body: %{"bitcoin" => %{"usd" => price}}}} ->
        {:ok, price}

      {:ok, _} ->
        {:error, :unexpected_response}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp schedule_fetch do
    Process.send_after(self(), :fetch, @interval)
  end
end
