defmodule WTH.Webhooks.Supervisor do
  # This module will accept a %Webhooks.Hook{} schema and then supervise:
  # * VM
  # * DynamicSupervisor for Executors
  #   * Each Executor is the combination of a Hook id and a state map
  #   * An Executor can only perform one execution at a time (waits on an execution to finish)

  use GenServer

  alias WTH.VM
  alias WTH.VM.Executor

  def start_link(hook: hook) do
    GenServer.start_link(__MODULE__, %{hook: hook}, name: via(:sup, hook.id))
  end

  def boot_sup(hook) do
    case GenServer.whereis(via(:sup, hook.id)) do
      nil ->
        DynamicSupervisor.start_child(
          WTH.Webhooks.SupervisorSupervisor,
          {__MODULE__, hook: hook}
        )
      pid -> {:ok, pid}
    end
  end

  def boot_exe(hook, state_id) do
    case GenServer.whereis(Executor.via(state_id)) do
      nil ->
        DynamicSupervisor.start_child(
          via(:exe_sup, hook.id),
          {Executor, vm: VM.via(hook.id), hook: hook, state_id: state_id}
        )
      pid -> {:ok, pid}
    end
  end

  def execute(hook, state_id, args) do
    with {:ok, _} <- boot_sup(hook),
         {:ok, _} <- boot_exe(hook, state_id) do
      Executor.execute(state_id, args)
    end
  end

  def via(type, id) do
    {:via, Registry, {WTH.VM.Registry, {type, id}}}
  end

  def init(%{hook: hook}) do
    children = [
      {VM, name: VM.via(hook.id), code: hook.code},
      {DynamicSupervisor, strategy: :one_for_one, name: via(:exe_sup, hook.id)}
    ]

    Supervisor.start_link(children, strategy: :one_for_all)
  end
end
