# whatthehook.com

A simple way to accept a webhook, do a small transformation, then forward along.

## About

This is a phoenix application that uses OTP to manage a process per account.
That process then manages running unsafe javascript code externally and
properly jailed.

## Development setup

Install elixir, erlang, node, and postgres.

Then:

```sh
$ mix hex.local
$ mix deps.get
$ mix ecto.reset
$ mix dialyxir.setup
$ cd assets && npm install && cd -
```

Run the server with:

```sh
mix phx.server
```

or interactive `iex` with:

```sh
iex -S mix
```

## Tests

Run the elixir tests with:

```sh
$ mix test
```

Also can do elixir linting with:

```sh
mix do dialyxir, credo
```

## Play around

This something like this:

```iex
iex(1)> hook = WTH.Repo.get(WTH.Webhooks.Hook, 1)
iex(2)> WTH.Webhooks.Supervisor.execute(hook, "a", %{})
iex(3)> WTH.Webhooks.Supervisor.execute(hook, "a", %{})
iex(4)> WTH.Webhooks.Supervisor.execute(hook, "b", %{})
```

Also `$ tail -f vm/debug.log` to see what the node vm thinks is going on.
