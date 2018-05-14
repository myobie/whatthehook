defmodule WTH.VM do
  require Logger
  use GenServer

  def init(%{notify: pid}) do
    Process.flag(:trap_exit, true)
    state = %{
      notify: pid,
      port: nil,
      prepared?: false,
      closing?: false,
      executions: %{}
    }
    {:ok, state}
  end

  defp write(port, term) do
    json = Poison.encode!(term)
    true = Port.command(port, :erlang.term_to_binary(json))
  end

  def handle_call({:start, code}, _from, state) do
    port = Port.open(
      {:spawn_executable, System.find_executable("npm")},
      [:binary, :use_stdio, :stderr_to_stdout, :exit_status,
       {:args, ['-s', 'run', 'server']},
       {:packet, 4},
       {:cd, Path.absname('./vm/')}]
    )

    write(port, %{type: :code, code: code})

    state = Map.put(state, :port, port)

    {:reply, :ok, state}
  end

  def handle_call(:close, _from, %{port: port} = state) do
    unless state.closing? do
      Port.close(port)
    end
    {:reply, :ok, %{state | closing?: true}}
  end

  def handle_call(:close, _from, state) do
    _ = Logger.debug("Closing a port that is not open #{inspect(self())}")
    {:reply, :ok, state}
  end

  def handle_call({:execute, args}, _from, %{port: port, executions: executions} = state) do
    cond do
      not state.prepared? -> {:reply, {:error, :unprepared}, state}
      true ->
        uuid = SecureRandom.uuid()
        executions = Map.put(executions, uuid, args)
        write(port, %{type: :args, args: args, uuid: uuid})
        {:reply, {:ok, uuid}, %{state | executions: executions}}
    end
  end

  defp handle_port_data({'ok', 'prepared'}, state) do
    {:noreply, %{state | prepared?: true}}
  end

  defp handle_port_data({'ok', uuid, result}, %{notify: pid} = state) do
    send(pid, {:ok, to_string(uuid), to_string(result)})
    {:noreply, state}
  end

  defp handle_port_data({'error', uuid, result}, %{notify: pid} = state) do
    send(pid, {:error, to_string(uuid), to_string(result)})
    {:noreply, state}
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
