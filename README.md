# Vercheckex
==========

### Elixir sample using HTTPoison, Floki and Timex.

### Fetching the release information from GitHub.

----------

## Prerequisite

*Elixir* language, *mix* build tool and *hex* package manager are installed.
Also Github setting is correctly completed.

## Build and run

    $ mix deps.get
    $ iex -S mix

After iex invoked, type

    iex(1)> VercheckEx.main []

## Build a command line executable

    $ mix escript.build

The command line executable, vercheckex is generated.

## Run Behind Proxy

Change 

```elixir
     ret = HTTPoison.get!( url )
```

to

```elixir
     ret = HTTPoison.get!( url, [], [{:proxy, "proxy.mycompany.com:port"}] )
```


