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
iex -S mix phx.server
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
iex(2)> WTH.Webhooks.execute_hook(hook, "a", %{})
```

Or with `curl`:

```sh
$ curl -i http://0.0.0.0:4000/hooks/1/a
$ curl -i http://0.0.0.0:4000/hooks/1/a
$ curl -i http://0.0.0.0:4000/hooks/1/b

$ curl -s http://0.0.0.0:4000/api/hooks/1 | jq -r '.code'
$ curl -s http://0.0.0.0:4000/api/hooks/2 | jq -r '.code'
```

Also `$ tail -f vm/debug.log` to see what the node vm thinks is going on.
