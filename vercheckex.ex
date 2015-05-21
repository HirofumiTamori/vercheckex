defmodule VercheckEx do
  require HTTPoison
  require Floki
  require Timex

  def fetch_content(url, type) do
    ret = HTTPoison.get!( url )

    %HTTPoison.Response{status_code: 200, body: body} = ret

    {_,_,n} = Floki.find(body, ".js-current-repository a") |> List.first
    {_, d} = Floki.find(body, "time") |> Floki.attribute("datetime") 
                                      |> List.first 
                                      |> Timex.DateFormat.parse("{ISOz}")
    if(type == :type1) do
      {_,_,x} = Floki.find(body, ".tag-name span") |> List.first
    else
      {_,_,x} = Floki.find(body, ".css-truncate-target span") |> List.first
    end

    d =Timex.Date.local(d, Timex.Date.timezone("JST"))

    {hd(n),hd(x),d}

  end

  def put_a_formatted_line(val) do
    {title, ver, date} = val
    l = title
    if String.length(title) < 8 do
      l = l <> "\t"
    end
    l = l <> "\t"
    l = l <> ver
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

end

urls = [
  {"https://github.com/jquery/jquery/releases", :type1},
  {"https://github.com/angular/angular/releases", :type1},
  {"https://github.com/facebook/react/releases", :type2},
  {"https://github.com/PuerkitoBio/goquery/releases", :type1},
  {"https://github.com/revel/revel/releases", :type2},
  {"https://github.com/lhorie/mithril.js/releases", :type1},
  {"https://github.com/muut/riotjs/releases", :type1},
  {"https://github.com/atom/atom/releases", :type2},
  {"https://github.com/Microsoft/TypeScript/releases", :type2},
  {"https://github.com/docker/docker/releases", :type1},
  {"https://github.com/JuliaLang/julia/releases", :type2},
  {"https://github.com/Araq/Nim/releases", :type1},
  {"https://github.com/elixir-lang/elixir/releases", :type2}]

Enum.each(urls, fn(i) -> 
  {u,t} = i
  VercheckEx.put_a_formatted_line VercheckEx.fetch_content(u,t)
end)
