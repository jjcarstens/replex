defmodule Replex.IR do
  use GenServer
  require Logger

  def start_link(ir_rec \\ 26, ir_send \\ 18) do
    GenServer.start_link(__MODULE__, [ir_rec, ir_send], name: __MODULE__)
  end

  def init([ir_rec, ir_send]) do
    {:ok, ir_rec} = Circuits.GPIO.open(ir_rec, :input)
    {:ok, ir_send} = Circuits.GPIO.open(ir_send, :output)
    Circuits.GPIO.set_interrupts(ir_rec, :both)

    {:ok, %{ir_rec: ir_rec, ir_send: ir_send, record?: false, recording: []}}
  end

  def decode(recording \\ nil) do
    recording = recording || state().recording

    marks = Enum.chunk_every(recording, 2)
    spaces = Enum.drop(recording, 1) |> Enum.chunk_every(2)

    raw = Enum.zip(marks, spaces)
    |> Enum.reduce([], fn {m, s}, acc ->
      case s do
        [{space_start, _}, {space_end, _}] ->
          [{start, _}, {end_time, _}] = m
          mark = (end_time - start)
          space = (space_end - space_start)
          bit = if space >= 1000, do: 1, else: 0
          [%{mark: mark, space: space, bit: bit} | acc]

        _ -> acc #skip
      end
    end)
    |> Enum.reverse()
    |> Enum.drop(1)
    |> Enum.take(32)
    |> Enum.reduce(<<>>, &(<<&2::bitstring, &1.bit::1>>))

    <<code_num::32>> = raw
    %{raw: raw, num: code_num, code: Integer.to_string(code_num, 16)}
  end

  def pulse(recording \\ nil), do: GenServer.call(__MODULE__, {:pulse, recording})

  def record(), do: GenServer.call(__MODULE__, :record)

  def state(), do: GenServer.call(__MODULE__, :get_state)

  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  def handle_call({:pulse, arg}, _from, %{ir_send: ir_send, recording: recording} = state) do
    recording = arg || recording
    Enum.reduce(recording, System.monotonic_time(:microsecond), &do_pulse(ir_send, &1, &2))
    Circuits.GPIO.write(ir_send, 0) # for good measure
    {:reply, :ok, state}
  end

  def handle_call(:record, _from, state) do
    Process.send_after(self(), :stop_recording, 5_000)

    {:reply, :ok, %{state | record?: true, recording: []}}
  end

  def handle_info({:circuits_gpio, _, time, val}, state) do
    state = if state.record?, do: %{state | recording: [{time/1000, val} | state.recording]}, else: state
    {:noreply, state}
  end

  def handle_info(:stop_recording, state) do
    {:noreply, %{state | record?: false, recording: Enum.sort_by(state.recording, &elem(&1, 0))}}
  end

  def handle_info(msg, state) do
    Logger.debug("some unknown message: #{inspect(msg)}")
  end

  defp do_pulse(pin, {time, val}, prev_time) do
    micro_sleep(time - prev_time)
    # val = if val == 1, do: 0, else: 1
    Circuits.GPIO.write(pin, val)
    time
  end

  defp micro_sleep(timeout, start \\ nil) do
    start = start || System.monotonic_time(:microsecond)
    if (System.monotonic_time(:microsecond) - start) >= timeout do
      :ok
    else
      micro_sleep(timeout, start)
    end
  end
end
