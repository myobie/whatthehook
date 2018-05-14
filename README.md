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
$ mix ecto.create
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
iex(1)> {:ok, pid} = GenServer.start_link(WTH.VM, %{})
iex(2)> GenServer.call(pid, {:start, "function request (req) { return {status: 200, body: { counter: req.params.counter * 2 }} }"})
iex(3)> GenServer.call(pid, {:execute, [%{params: %{counter: 4}}]})
iex(4)> GenServer.call(pid, {:execute, [%{params: %{counter: 22}}]})
iex(5)> GenServer.call(pid, :close)
```

Also `$ tail -f vm/debug.log` to see what the node vm thinks is going on.
