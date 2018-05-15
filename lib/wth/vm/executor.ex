defmodule WTH.VM.Executor do
  use GenServer

  def start_link(vm: vm, state_id: state_id) do
    GenServer.start_link(__MODULE__, %{vm: vm, state_id: state_id}, name: via(state_id))
  end

  def execute(state_id, args) do
    GenServer.call(via(state_id), {:execute, args})
  end

  def via(id) do
    {:via, Registry, {WTH.VM.Registry, {:exe, id}}}
  end

  def init(%{vm: vm}) do
    # TODO: fetch initial state from the database
    {:ok, %{vm: vm, internal: %{}}}
  end

  def handle_call({:execute, args}, _from, %{vm: vm, internal: internal} = state) do
    args = Map.put(args, :state, internal)

    with {:ok, uuid} <- WTH.VM.execute(vm, [args]) do
      receive do
        {reason, ^uuid, result} ->
          case Poison.decode(result) do
            {:ok, json} ->
              state = Map.put(state, :internal, Map.get(json, "state", %{}))
              # TODO: persist new state to the database if changed
              {:reply, {reason, json}, state}
            {:error, _} ->
              {:reply, {reason, result}, state}
          end
      end
    end
  end
end
