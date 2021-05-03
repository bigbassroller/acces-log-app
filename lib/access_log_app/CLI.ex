defmodule AccessLogApp.CLI do
  @github_url Application.get_env(:access_log_app, :github_url)

  def fetch() do
    HTTPoison.get("#{@github_url}")
    |> handle_response
  end

  def handle_response({_, %{status_code: status_code, body: body}}) do
    {
      status_code |> check_for_error(),
      body
      |> split_by_line
      |> Enum.drop(1)
      |> split_by_space
      |> get_data(["http", "TCP"])
      |> filter_list_by_strings([
        "c13.adrise.tv/04C0BF/v2/sources/content-owners",
        "c13.adrise.tv/04C0BF/ads/transcodes"
      ])
      |> get_id_from_url_path
      |> group_by_id
      |> get_cache_hit_misses
      |> calculate_cache_hit_misses
      |> integer_to_percent("TCP_hit_percentage")
      |> sort_by_field(:video_id)
    }
  end

  def sort_by_field(list, field_name) do
    Enum.sort(list, fn i1, i2 ->
      Map.get(i1, field_name) <= Map.get(i2, field_name)
    end)
  end

  def integer_to_percent(lines, field_name) do
    Enum.map(lines, fn item ->
      raw_percent = item
      |> Map.get(field_name)
      |> Number.Percentage.number_to_percentage(precision: 2)
      |> String.split(".")
      |> Enum.join

      percent = case raw_percent do
        "100%"  -> "100%"
        "000%"  -> "0%"
        _  -> String.split(raw_percent, "0") |> Enum.join
      end

      video_id = item
      |> Map.get(:video_id)

      %{:video_id => video_id, field_name => percent}
    end)
  end

  def calculate_cache_hit_misses(list) do
    list
    |> Enum.map(fn item ->
      video_id = item
      |> Map.get(:video_id)

      hits = item
      |> Map.get("HIT")

      misses = item
      |> Map.get("MISS")

      hit_total = hits + misses
      hit_percentage = hits / hit_total

      %{}
      |> Map.put(:video_id, video_id)
      |> Map.put("TCP_hit_percentage", hit_percentage)
    end)
  end

  def get_cache_hit_misses(list) do
    Enum.map(list, fn hit_percentage ->
      video_id = hit_percentage
      |> elem(0)
      |> Enum.map(&elem(&1,1))
      |> hd

      hit_percentage
      |> elem(1)
      |> Enum.map(fn x ->
        case x do
          [_, tcp: tcp] ->
            tcp
            |> String.trim("TCP_")
            |> String.split("/")
            |> case do
              ["HIT", _] -> List.insert_at([], -1, "HIT")
              ["MISS", _] -> List.insert_at([], -1, "MISS")
            end
        end
      end)
      |> Enum.map(&List.first(&1))
      |> Enum.reduce(%{"HIT" => 0, "MISS" => 0}, fn x, acc -> Map.update(acc, x, 1, &(&1 + 1)) end)
      |> Map.put(:video_id, video_id)
    end)
  end

  def group_by_id(list) do
    Enum.group_by(list, fn [video_id, _] ->
      [video_id]
    end)
  end

  def get_id_from_url_path(list) do
    list
    |> Enum.map(fn entries ->
      Enum.map(entries, fn items ->
        Tuple.to_list(items)
        |> case do
          [:http, url] ->
            [video_id | _] = url
            |> String.split("/")
            |> Enum.map(fn keep_if_int ->
              case Regex.match?(~r(\b^\d{6}\b|\b^\d{5}\b|\b^\d{4}\b), keep_if_int) do
                true -> keep_if_int
                _ -> ""
              end
            end)
            |> Enum.filter(& !is_blank(&1))

            {:video_id, elem(Integer.parse(video_id), 0)}
          [k, v] -> {k, v}
          _ -> ""
        end
      end)
    end)
  end


  @doc """
  Filter List.
  Takes a list containing URLS and filters by directory paths
  ## Examples

      iex> filter_list_by_strings([
      [
        http: "http://yadayadayada1.ts/yep/a/b/c/blah-blah/123456/01234-56789.1011.ts",
        tcp: "TCP_HIT/206"
      ],
      [
        http: "http://yadayadayada1.ts/nope/a/b/c/blah-blah/123456/01234-56789.1011.ts",
        tcp: "TCP_HIT/200"
      ],
      [
        http: "http://yadayadayada2.ts/yep/d/e/f/blah-blah/blah-blah/123456/01234-56789.1011.ts",
        tcp: "TCP_HIT/200"
      ],
      [
        http: "http://yadayadayada2.ts/nope/d/e/f/blah-blah/blah-blah/123456/01234-56789.1011.ts",
        tcp: "TCP_HIT/200"
      ]
    ], ["yadayadayada1.ts/yep/a/b/c", "yadayadayada2.ts/yep/d/e/f"])
      [
        [
          http: "http://yadayadayada1.ts/yep/a/b/c/blah-blah/123456/01234-56789.1011.ts",
          tcp: "TCP_HIT/206"
        ],
        [
          http: "http://yadayadayada2.ts/yep/d/e/f/blah-blah/blah-blah/123456/01234-56789.1011.ts",
          tcp: "TCP_HIT/200"
        ]
      ]
  """
  def filter_list_by_strings(list, paths) do
    [a, b] = paths
    Enum.filter(list, fn item  ->
      http = item
      |> hd
      |> elem(1)
      Regex.match?(~r/http:\/\/((#{a}[-a-zA-Z0-9\+.]*|#{b}))\//,"#{http}")
    end)
  end

  @doc """
  Get data.

  ## Examples

      iex> get_data([
      ["12345", "0", "TCP_HIT/206", "393359", "GET", "http://yadayadayada1.ts", "beep", "bop", "boop"],
      ["12345", "1", "TCP_HIT/200", "393359", "GET", "http://yadayadayada2.ts", "beep", "bop", "boop"],
      ["12345", "2", "TCP_HIT/206", "393359", "GET", "http://yadayadayada3.ts", "beep", "bop", "boop"]
    ], "")
      [
        [
          http: "http://yadayadayada1.ts",
          tcp: "TCP_HIT/206"
        ],
        [
          http: "http://yadayadayada2.ts",
          tcp: "TCP_HIT/200"
        ],
        [
          http: "http://yadayadayada3.ts",
          tcp: "TCP_HIT/206"
        ]
      ]
  """
  def get_data(list, strings) do
    Enum.map(list, fn item ->
      Enum.map(strings, fn string ->
        {
          String.to_atom(String.downcase(string)),
          Enum.at(Enum.filter(item, &String.contains?(&1, string)), 0)
        }
      end)
    end)
  end

  @doc """
  Split by line.

  ## Examples

      iex> split_by_line("a b c\na b c")
      ["a b c", "a b c"]

  """
  def split_by_line(lines) do
    String.split(lines, "\n", trim: true)
  end


  @doc """
  Split by line.

  ## Examples

      iex> split_by_space(["a b c", "a b c"])
      ["a", "b", "c", "a", "b", "c"]

  """
  def split_by_space(lines) do
    lines
    |> Enum.map(&String.split(&1," "))
  end

  def is_blank(nil), do: true
  def is_blank(val) when val == %{}, do: true
  def is_blank(val) when val == [], do: true
  def is_blank(val) when is_binary(val), do: String.trim(val) == ""
  def is_blank(_val), do: false

  def check_for_error(200), do: :ok
  def check_for_error(_), do: :error
end