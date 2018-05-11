defmodule Whathook.VM do
  use GenServer

  def init(_) do
    Process.flag(:trap_exit, true)
    {:ok, %{}}
  end

  def handle_call(:start, _from, state) do
    port = Port.open(
      {:spawn_executable, System.find_executable("npm")},
      [:binary, :use_stdio, :stderr_to_stdout, :exit_status,
       {:args, ['-s', 'run', 'server']},
       {:packet, 4},
       {:cd, Path.absname('./vm/')}]
    )

    state = Map.put(state, :port, port)

    {:reply, :ok, state}
  end

  def handle_call(:close, _from, %{port: port} = state) do
    Port.close(port)
    {:reply, :ok, state}
  end

  def handle_call({:command, command}, _from, %{port: port} = state) do
    result = Port.command(port, :erlang.term_to_binary(command))
    {:reply, result, state}
  end

  def handle_info({_from, {:data, data}}, state) do
    term = :erlang.binary_to_term(data, [:safe])
    IO.inspect({:received_term, term})
    {:noreply, state}
  end

  def handle_info({from_port, {:exit_status, status}}, state) when is_port(from_port) do
    IO.inspect({:EXIT, "the port process exited with status #{status}"})
    {:noreply, state}
  end

  def handle_info({:EXIT, from_port, reason}, %{port: port} = state) when from_port == port do
    IO.inspect({:EXIT, "the port died (#{inspect(reason)}), cleaning up"})
    state = Map.delete(state, :port)
    {:noreply, state}
  end

  def handle_info({:EXIT, from, reason}, state) do
    IO.inspect({:EXIT, "something died?", from, reason})
    {:noreply, state}
  end
end
