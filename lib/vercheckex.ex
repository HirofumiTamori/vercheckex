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
        
  defp parse_title(body, :type1) do
    try do
      {_,[{_,_}],x} = Floki.find(body, ".tag-name") |> List.first
      {:ok, x}
    rescue
      what -> {:error, what}
    end
  end 

  defp parse_title(body, :type2) do
    try do
      {_,[{_,_}],x} = Floki.find(body, ".release-title a") |> List.first
      {:ok, x}
    rescue
      what -> {:error, what}
    end
  end

  def fetch_content(param) do
    {{url}, i} = param
    #IO.puts "URL = #{url}"
    #IO.puts "i = #{i}"
    ret = HTTPoison.get!( url )

    %HTTPoison.Response{status_code: 200, body: body} = ret

    {_,_,n} = Floki.find(body, ".container strong a") |> List.first
    {_, d} = Floki.find(body, "time") |> Floki.attribute("datetime") 
                                      |> List.first 
                                      |> Timex.DateFormat.parse("{ISOz}")
                                      

    {result,x} = parse_title(body, :type1)
    # retry if parse_title failed(with Missing Pattern Error)
    if result == :error do
      {_,x} = parse_title(body, :type2)
      x
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
    urls = [ #{ URL }
      {"https://github.com/jquery/jquery/releases"},
      {"https://github.com/angular/angular/releases"},
      {"https://github.com/facebook/react/releases"},
      {"https://github.com/PuerkitoBio/goquery/releases"},
      {"https://github.com/revel/revel/releases"},
      {"https://github.com/lhorie/mithril.js/releases"},
      {"https://github.com/riot/riot/releases"},
      {"https://github.com/atom/atom/releases"},
      {"https://github.com/Microsoft/TypeScript/releases"},
      {"https://github.com/docker/docker/releases"},
      {"https://github.com/JuliaLang/julia/releases"},
      {"https://github.com/nim-lang/Nim/releases"},
      {"https://github.com/elixir-lang/elixir/releases"},
      {"https://github.com/philss/floki/releases"},
      {"https://github.com/takscape/elixir-array/releases"},
    ]

    urls
    |> Enum.with_index
    |> Enum.map(&(Task.async(fn -> fetch_content(&1) end)))
    |> Enum.map(&(Task.await(&1,10000)))
    |> Enum.sort(fn(a,b) ->
      {:ok, {_, _, _, i1}} = a
      {:ok, {_, _, _, i2}} = b
      i1 < i2
    end
    )
    |> Enum.map(&put_a_formatted_line/1)

  end

end

