defmodule VercheckEx do
  use Application
  use GenServer
  require HTTPoison
  require Floki
  require Timex

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    children = [
    ]
    opts = [strategy: :one_for_one, name: VercheckEx.Supervisor]
    Supervisor.start_link(children, opts)
  end
        

  def fetch_content(param) do
    {{url, type}, i} = param
    #IO.puts "URL = #{url}"
    #IO.puts "i = #{i}"
    ret = HTTPoison.get!( url )

    %HTTPoison.Response{status_code: 200, body: body} = ret

    {_,_,n} = Floki.find(body, ".container strong a") |> List.first
    {_, d} = Floki.find(body, "time") |> Floki.attribute("datetime") 
                                      |> List.first 
                                      |> Timex.DateFormat.parse("{ISOz}")
    if(type == :type1) do
      {_,[{_,_}],x} = Floki.find(body, ".tag-name") |> List.first
    else
      {_,[{_,_}],x} = Floki.find(body, ".release-title a") |> List.first
    end
    d |> Timex.Date.Convert.to_erlang_datetime
      |> Timex.Date.from "Asia/Tokyo"
      #IO.inspect n
    {:ok, {hd(n),hd(x),d,i}}
  end

  defp put_a_formatted_line(val) do
    {:ok, {title, ver, date, _}} = val
    l = title
    if String.length(title) < 8 do
      l = l <> "\t"
    end
    l = l <> "\t" <> ver
    if String.length(ver) < 8 do
      l = l <> "\t"
    end
    l = l <> "\t" <> Timex.DateFormat.format!(date, "%Y.%m.%d", :strftime)

    now = Timex.Date.now("JST")
    diff =  Timex.Date.diff( date, now, :days)
    if diff < 14 do
      l = l <> "\t<<<<< updated at " <> Integer.to_string(diff) <> " day(s) ago."
    end
    IO.puts(l)
  end


  def main(args) do
    urls = [ #{ URL, type}
      {"https://github.com/jquery/jquery/releases", :type1},
      {"https://github.com/angular/angular/releases", :type1},
      {"https://github.com/facebook/react/releases", :type2},
      {"https://github.com/PuerkitoBio/goquery/releases", :type1},
      {"https://github.com/revel/revel/releases", :type2},
      {"https://github.com/lhorie/mithril.js/releases", :type1},
      {"https://github.com/riot/riot/releases", :type1},
      {"https://github.com/atom/atom/releases", :type2},
      {"https://github.com/Microsoft/TypeScript/releases", :type2},
      {"https://github.com/docker/docker/releases", :type2},
      {"https://github.com/JuliaLang/julia/releases", :type2},
      {"https://github.com/nim-lang/Nim/releases", :type1},
      {"https://github.com/elixir-lang/elixir/releases", :type2},
      {"https://github.com/philss/floki/releases", :type1},
      {"https://github.com/takscape/elixir-array/releases", :type2},
    ]

    urls
    |> Enum.with_index
    |> Enum.map(&(Task.async(fn -> fetch_content(&1) end)))
    |> Enum.map(&(Task.await/1))
    |> Enum.sort(fn(a,b) ->
      {:ok, {_, _, _, i1}} = a
      {:ok, {_, _, _, i2}} = b
      i1 < i2
    end
    )
    |> Enum.map(&put_a_formatted_line/1)

  end

end

