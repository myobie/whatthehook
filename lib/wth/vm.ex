defmodule WTH.VM do
  require Logger
  use GenServer

  def start_link(name: name, code: code) do
    GenServer.start_link(__MODULE__, %{code: code}, name: name)
  end

  def execute(vm, args) do
    GenServer.call(vm, {:execute, args})
  end

  def close(vm) do
    GenServer.call(vm, :close)
  end

  def stop(vm) do
    GenServer.stop(vm)
  end

  def via(id) do
    {:via, Registry, {WTH.VM.Registry, {:vm, id}}}
  end

  def init(%{code: code}) do
    Process.flag(:trap_exit, true)

    port = Port.open(
      {:spawn_executable, System.find_executable("npm")},
      [:binary, :use_stdio, :stderr_to_stdout, :exit_status,
       {:args, ['-s', 'run', 'server']},
       {:packet, 4},
       {:cd, Path.absname('./vm/')}]
    )

    write(port, %{type: :prepare, code: code})

    receive do
      {^port, {:data, data}} ->
        case :erlang.binary_to_term(data, [:safe]) do
          {'ok', 'prepared'} ->
            state = %{
              port: port,
              closing?: false,
              executions: %{}
            }

            {:ok, state}
          other ->
            _ = Logger.error("Received unexpected message from port #{inspect(other)}")
            {:error, other}
        end
      after
        1_000 ->
          _ = Logger.error("No data received from port after 1 second")
          {:error, :failed_to_start}
    end
  end

  defp write(port, term) do
    json = Poison.encode!(term)
    true = Port.command(port, :erlang.term_to_binary(json))
  end

  def handle_call(:close, _from, %{port: port, closing?: false} = state) when is_port(port) do
    Port.close(port)
    {:reply, :ok, %{state | closing?: true}}
  end

  def handle_call(:close, _from, state) do
    {:reply, :ok, state}
  end

  def handle_call({:execute, _args}, _from, %{prepared?: false} = state) do
    {:reply, {:error, :unprepared}, state}
  end

  def handle_call({:execute, args}, {pid, _ref}, %{port: port, executions: executions} = state) do
    uuid = SecureRandom.uuid()
    executions = Map.put(executions, uuid, %{args: args, pid: pid})
    write(port, %{type: :execute, args: args, uuid: uuid})
    {:reply, {:ok, uuid}, %{state | executions: executions}}
  end

  defp send_back(%{executions: executions} = state, {_, uuid, _} = msg) do
    case Map.fetch(executions, uuid) do
      :error ->
        _ = Logger.error("Execution missing for #{uuid}")
        {:noreply, state}
      {:ok, %{pid: pid}} ->
        send(pid, msg)
        executions = Map.delete(executions, uuid)
        {:noreply, %{state | executions: executions}}
    end
  end

  defp handle_port_data({'ok', uuid, result}, state) do
    send_back(state, {:ok, to_string(uuid), to_string(result)})
  end

  defp handle_port_data({'error', uuid, result}, state) do
    send_back(state, {:error, to_string(uuid), to_string(result)})
  end

  defp handle_port_data(term, state) do
    _ = Logger.error("Unknown data sent from node vm: #{inspect(term)}")
    {:noreply, state}
  end

  def handle_info({_from, {:data, data}}, state) do
    data
    |> :erlang.binary_to_term([:safe])
    |> handle_port_data(state)
  end

  def handle_info({from_port, {:exit_status, status}}, state) when is_port(from_port) do
    IO.inspect({:EXIT, "the port process exited with status #{status}"})
    {:noreply, state}
  end

  def handle_info({:EXIT, from_port, reason}, %{port: port} = state) when from_port == port do
    IO.inspect({:EXIT, "the port died (#{inspect(reason)}), cleaning up"})
    {:noreply, %{state | port: nil, closing?: false}}
  end

  def handle_info({:EXIT, from, reason}, state) do
    IO.inspect({:EXIT, "something died?", from, reason})
    {:noreply, state}
  end
end
