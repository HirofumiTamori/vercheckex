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
    $ mix run vercheck.ex

## Run Behind Proxy

Change 

```elixir
     ret = HTTPoison.get!( url )
```

to

```elixir
     ret = HTTPoison.get!( url, [], [{:proxy, {"proxy.yoursite.com", 8080}}])  )
```


