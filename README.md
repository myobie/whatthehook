# whathook.com

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

## Tests

Run the elixir tests with:

```sh
$ mix test
```

Also can do elixir linting with:

```sh
mix do dialyxir, credo
```


