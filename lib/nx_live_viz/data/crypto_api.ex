defmodule NxLiveViz.Data.CryptoAPI do
  @moduledoc "Fetches cryptocurrency price data as time series."

  use NxLiveViz.Data.ActiveSource

  require Logger

  @api_url "https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT"

  @impl NxLiveViz.Data.ActiveSource
  def source_interval, do: 3_000

  @impl NxLiveViz.Data.ActiveSource
  def init_state(opts) do
    %{active: Keyword.get(opts, :active, false), last_value: nil}
  end

  @impl NxLiveViz.Data.ActiveSource
  def collect(state) do
    case fetch_price() do
      {:ok, price} ->
        point = %{
          value: price * 1.0,
          timestamp: DateTime.utc_now(),
          anomaly: false
        }

        NxLiveViz.broadcast_sensor_data(point)
        %{state | last_value: price}

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

        state
    end
  end

  defp fetch_price do
    case Req.get(@api_url) do
      {:ok, %Req.Response{status: 200, body: %{"price" => price_str}}} ->
        {price, _} = Float.parse(price_str)
        {:ok, price}

      {:ok, _} ->
        {:error, :unexpected_response}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
