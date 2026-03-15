defmodule NxLiveViz.Data.CryptoAPITest do
  use ExUnit.Case, async: true

  alias NxLiveViz.Data.CryptoAPI

  test "starts with active: false by default" do
    pid = start_supervised!({CryptoAPI, [name: :crypto_test_default]})
    state = :sys.get_state(pid)

    assert state.active == false
    assert state.last_value == nil
  end

  test "activate/1 sets active to true" do
    pid = start_supervised!({CryptoAPI, [name: :crypto_test_activate]})

    CryptoAPI.activate(:crypto_test_activate)
    # Synchronize with the GenServer to ensure the cast has been processed
    state = :sys.get_state(pid)

    assert state.active == true
  end

  test "deactivate/1 sets active to false" do
    pid = start_supervised!({CryptoAPI, [name: :crypto_test_deactivate, active: true]})

    # Verify it started active
    state = :sys.get_state(pid)
    assert state.active == true

    CryptoAPI.deactivate(:crypto_test_deactivate)
    state = :sys.get_state(pid)

    assert state.active == false
  end

  test "does not fetch when inactive" do
    pid = start_supervised!({CryptoAPI, [name: :crypto_test_inactive]})

    # Send a :fetch message directly while inactive
    send(pid, :fetch)
    state = :sys.get_state(pid)

    # last_value should remain nil since the server is inactive
    assert state.last_value == nil
    assert state.active == false
  end

  test "activate then deactivate round-trips state" do
    pid = start_supervised!({CryptoAPI, [name: :crypto_test_roundtrip]})

    CryptoAPI.activate(:crypto_test_roundtrip)
    state = :sys.get_state(pid)
    assert state.active == true

    CryptoAPI.deactivate(:crypto_test_roundtrip)
    state = :sys.get_state(pid)
    assert state.active == false
  end
end
