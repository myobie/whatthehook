defmodule WTH.VM.Executor do
  use GenServer

  alias WTH.Webhooks

  def start_link(vm: vm, hook: hook, state_id: state_id) do
    GenServer.start_link(__MODULE__, %{vm: vm, hook: hook, state_id: state_id}, name: via(state_id))
  end

  def execute(state_id, args) do
    GenServer.call(via(state_id), {:execute, args})
  end

  def via(id) do
    {:via, Registry, {WTH.VM.Registry, {:exe, id}}}
  end

  def init(%{vm: vm, hook: hook, state_id: uuid}) do
    with {:ok, hook_state} <- Webhooks.get_or_create_hook_state(hook.id, uuid) do
      {:ok, %{vm: vm, hook_state: hook_state}}
    end
  end

  def handle_call({:execute, args}, _from, %{vm: vm, hook_state: hook_state} = state) do
    args = Map.put(args, :state, hook_state.value)

    with {:ok, uuid} <- WTH.VM.execute(vm, [args]) do
      receive do
        {reason, ^uuid, result} ->
          case Poison.decode(result) do
            {:ok, json} ->
              with %{"state" => new_value} <- json,
                   {:ok, hook_state} <- Webhooks.update_hook_state(hook_state, %{value: new_value}) do
                {:reply, {reason, json}, %{state | hook_state: hook_state}}
              end
            {:error, _} ->
              {:reply, {reason, result}, state}
          end
      end
    end
  end
end
