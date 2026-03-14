defmodule NxLiveViz.Data.CryptoAPI do
  @moduledoc "Fetches cryptocurrency price data as time series."

  use GenServer

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
    {:ok, %{active: active}}
  end

  def activate(server \\ __MODULE__) do
    GenServer.cast(server, :activate)
  end

  def deactivate(server \\ __MODULE__) do
    GenServer.cast(server, :deactivate)
  end

  @impl true
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

        Phoenix.PubSub.broadcast(NxLiveViz.PubSub, "sensor:data", {:sensor_data, point})

      {:error, _reason} ->
        :ok
    end

    schedule_fetch()
    {:noreply, state}
  end

  defp fetch_price do
    case :httpc.request(:get, {~c"#{@api_url}", []}, [timeout: 5_000], []) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        case Jason.decode(body) do
          {:ok, %{"bitcoin" => %{"usd" => price}}} -> {:ok, price}
          _ -> {:error, :parse_error}
        end

      _ ->
        {:error, :request_failed}
    end
  end

  defp schedule_fetch do
    Process.send_after(self(), :fetch, @interval)
  end
end
