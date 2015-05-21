defmodule VercheckEx do
  require HTTPoison
  require Floki
  require Timex

  def fetch_content() do
    receive do
      {caller, url, type, i} ->
        #IO.puts "URL = #{url}"
        ret = HTTPoison.get!( url )

        %HTTPoison.Response{status_code: 200, body: body} = ret

        {_,_,n} = Floki.find(body, ".js-current-repository a") |> List.first
        {_, d} = Floki.find(body, "time") |> Floki.attribute("datetime") 
                                          |> List.first 
                                          |> Timex.DateFormat.parse("{ISOz}")
        if(type == :type1) do
          #IO.puts "type1"
          {_,_,x} = Floki.find(body, ".tag-name span") |> List.first
        else
          {_,_,x} = Floki.find(body, ".css-truncate-target span") |> List.first
        end
        d =Timex.Date.local(d, Timex.Date.timezone("JST"))
        send caller, {:ok, {hd(n),hd(x),d,i}}
        # this process dies after sending the message.
      end
  end

  def put_a_formatted_line(val) do
    {title, ver, date, _} = val
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

  def receiver(result_list, n) do
    if( length(result_list) < n ) do
      receive do
        {:ok, res} ->
          receiver( result_list++[res], n )
      end
    else # all results are gathered
      Enum.sort(result_list, fn(a,b) -> # sort by index number
        {_,_,_,i1} = a
        {_,_,_,i2} = b
        i1 < i2 end)|>Enum.each( fn(x) -> put_a_formatted_line x end)
    end
  end
end

urls = [ #{ URL, type, index}
  {"https://github.com/jquery/jquery/releases", :type1, 0},
  {"https://github.com/angular/angular/releases", :type1, 1},
  {"https://github.com/facebook/react/releases", :type2, 2},
  {"https://github.com/PuerkitoBio/goquery/releases", :type1, 3},
  {"https://github.com/revel/revel/releases", :type2, 4},
  {"https://github.com/lhorie/mithril.js/releases", :type1, 5},
  {"https://github.com/muut/riotjs/releases", :type1, 6},
  {"https://github.com/atom/atom/releases", :type2, 7},
  {"https://github.com/Microsoft/TypeScript/releases", :type2, 8},
  {"https://github.com/docker/docker/releases", :type1, 9},
  {"https://github.com/JuliaLang/julia/releases", :type2, 10},
  {"https://github.com/Araq/Nim/releases", :type1, 11},
  {"https://github.com/elixir-lang/elixir/releases", :type2, 12},
  {"https://github.com/philss/floki/releases", :type1, 13},
  {"https://github.com/takscape/elixir-array/releases", :type2, 14},
]

# Spawn processes upto the number of URLs
fetchers = for _ <- 0..length(urls), do: spawn_link fn -> VercheckEx.fetch_content() end

Enum.each( urls, fn(x) ->
  {u,t,i} = x
  send Enum.at(fetchers,i), {self, u, t, i}
end)

result_list = []
VercheckEx.receiver(result_list, length(urls))
