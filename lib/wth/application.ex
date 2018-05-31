defmodule WTH.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(WTH.Repo, []),
      {Registry, keys: :unique, name: WTH.VM.Registry},
      {DynamicSupervisor, strategy: :one_for_one, name: WTH.Webhooks.SupervisorSupervisor},
      supervisor(WTHWeb.Endpoint, [])
    ]

    opts = [strategy: :rest_for_one, name: WTH.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
