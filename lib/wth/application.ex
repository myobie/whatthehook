defmodule WTH.Application do
  @moduledoc false

  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(WTH.Repo, []),
      # Start the endpoint when the application starts
      supervisor(WTHWeb.Endpoint, []),
      # Start your own worker by calling: WTH.Worker.start_link(arg1, arg2, arg3)
      # worker(WTH.Worker, [arg1, arg2, arg3]),

      {Registry, keys: :unique, name: WTH.VM.Registry}
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WTH.Supervisor]
    Supervisor.start_link(children, opts)
  end
end