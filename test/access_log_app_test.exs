defmodule AccessLogAppTest do
  use ExUnit.Case
  doctest AccessLogApp

  import AccessLogApp.CLI, only: [
    split_by_line: 1,
    split_by_space: 1,
    get_data: 2,
    filter_list_by_strings: 2,
    get_id_from_url_path: 1,
    group_by_id: 1,
    get_cache_hit_misses: 1,
    integer_to_percent: 2,
    sort_by_field: 2
  ]

  test "greets the world" do
    assert AccessLogApp.hello() == :world
  end

  test "splits file that is line separate" do
    data = "a http://example.com/1 TCP_HIT/200\na http://example.com/2 TCP_HIT/200\n\n"
    result = split_by_line(data)
    assert result == ["a b c", "a b c"]
  end

	test "splits lists by spaces" do
		data = ["a b c", "a b c"]
		result = split_by_space(data)
		assert result == [
			["TCP_HIT/200", "http://example.com/1"],
			["TCP_HIT/200", "http://example.com/2"]
		]
  end

  test "gets data from an array containing strings to match" do
  	list = [
			["12345", "0", "TCP_HIT/206", "393359", "GET", "http://yadayadayada1.ts", "beep", "bop", "boop"],
			["22345", "1", "TCP_HIT/200", "393359", "GET", "http://yadayadayada2.ts", "beep", "bop", "boop"],
			["32345", "2", "TCP_HIT/206", "393359", "GET", "http://yadayadayada3.ts", "beep", "bop", "boop"]
  	]
  	result = get_data(list, ["http", "TCP"])
  	assert result == [
      [http: "http://yadayadayada1.ts", tcp: "TCP_HIT/206"],
      [http: "http://yadayadayada2.ts", tcp: "TCP_HIT/200"],
      [http: "http://yadayadayada3.ts", tcp: "TCP_HIT/206"]
  	]
  end

  test "filters list by strings" do
    list = [
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
    ]
    result = filter_list_by_strings(list, ["yadayadayada1.ts/yep/a/b/c", "yadayadayada2.ts/yep/d/e/f"])
    assert result == [
      [
        http: "http://yadayadayada1.ts/yep/a/b/c/blah-blah/123456/01234-56789.1011.ts",
        tcp: "TCP_HIT/206"
      ],
      [
        http: "http://yadayadayada2.ts/yep/d/e/f/blah-blah/blah-blah/123456/01234-56789.1011.ts",
        tcp: "TCP_HIT/200"
      ]
    ]
  end

  test "Gets first integer in URL path" do
    data = [
  		[
  			http: "http://yadayadayada1.ts/yep/a/b/c/blah-blah/654321/01234-56789.1011.ts",
  			tcp_hit: "TCP_HIT/206"
  		],
  		[
  			http: "http://yadayadayada2.ts/yep/d/e/f/blah-blah/blah-blah/123456/01234-56789.1011.ts",
  			tcp_hit: "TCP_HIT/200"
  		]
    ]
    result = get_id_from_url_path(data)
    assert result == [
      [ video_id: 654321,
        tcp_hit: "TCP_HIT/206"
      ],
      [
        video_id: 123456,
        tcp_hit: "TCP_HIT/200"
      ]
    ]
  end

  test "Groups list by video_id" do
    list = [
     [video_id: 1, tcp: "TCP_HIT/200"],
     [video_id: 1, tcp: "TCP_HIT/200"],
     [video_id: 1, tcp: "TCP_HIT/206"],
     [video_id: 1, tcp: "TCP_HIT/304"],
     [video_id: 2, tcp: "TCP_HIT/200"],
     [video_id: 2, tcp: "TCP_HIT/200"],
     [video_id: 2, tcp: "TCP_HIT/206"],
     [video_id: 2, tcp: "TCP_HIT/304"],
     [video_id: 3, tcp: "TCP_HIT/200"],
     [video_id: 3, tcp: "TCP_HIT/200"],
     [video_id: 3, tcp: "TCP_HIT/206"],
     [video_id: 3, tcp: "TCP_HIT/304"],
     [video_id: 4, tcp: "TCP_HIT/200"],
     [video_id: 4, tcp: "TCP_HIT/200"],
     [video_id: 4, tcp: "TCP_HIT/206"],
     [video_id: 4, tcp: "TCP_HIT/304"]
    ]
    result = group_by_id(list)
    assert result ==  %{
      [video_id: 1] => [
       [video_id: 1, tcp: "TCP_HIT/200"],
       [video_id: 1, tcp: "TCP_HIT/200"],
       [video_id: 1, tcp: "TCP_HIT/206"],
       [video_id: 1, tcp: "TCP_HIT/304"]
      ],
      [video_id: 2] => [
       [video_id: 2, tcp: "TCP_HIT/200"],
       [video_id: 2, tcp: "TCP_HIT/200"],
       [video_id: 2, tcp: "TCP_HIT/206"],
       [video_id: 2, tcp: "TCP_HIT/304"]
      ],
      [video_id: 3] => [
       [video_id: 3, tcp: "TCP_HIT/200"],
       [video_id: 3, tcp: "TCP_HIT/200"],
       [video_id: 3, tcp: "TCP_HIT/206"],
       [video_id: 3, tcp: "TCP_HIT/304"]
      ],
      [video_id: 4] => [
       [video_id: 4, tcp: "TCP_HIT/200"],
       [video_id: 4, tcp: "TCP_HIT/200"],
       [video_id: 4, tcp: "TCP_HIT/206"],
       [video_id: 4, tcp: "TCP_HIT/304"]
      ]
    }
  end

  test "Get cache hit/misses for each video_id" do
    list = %{
      [video_id: "1", tcp: "TCP_HIT/200"] => [
        [video_id: "1", tcp: "TCP_HIT/200"],
        [video_id: "1", tcp: "TCP_HIT/200"],
        [video_id: "1", tcp: "TCP_HIT/200"]
      ],
      [video_id: "2", tcp: "TCP_HIT/206"] => [
        [video_id: "2", tcp: "TCP_HIT/206"],
        [video_id: "2", tcp: "TCP_HIT/206"],
        [video_id: "2", tcp: "TCP_HIT/206"]
      ],
      [video_id: "3", tcp: "TCP_MISS/206"] => [
        [video_id: "3", tcp: "TCP_MISS/206"],
        [video_id: "3", tcp: "TCP_MISS/206"],
        [video_id: "3", tcp: "TCP_MISS/206"]
      ],
      [video_id: "4", tcp: "TCP_HIT/206"] => [
        [video_id: "4", tcp: "TCP_HIT/206"],
        [video_id: "4", tcp: "TCP_HIT/206"],
        [video_id: "4", tcp: "TCP_HIT/206"]
      ],
      [video_id: "5", tcp: "TCP_HIT/206"] => [
        [video_id: "5", tcp: "TCP_MISS/206"],
        [video_id: "5", tcp: "TCP_HIT/206"],
        [video_id: "5", tcp: "TCP_HIT/206"]
      ]
    }
    result = get_cache_hit_misses(list)
    assert result ==  [
      %{:video_id => "1", "HIT" => 3, "MISS" => 0},
      %{:video_id => "2", "HIT" => 3, "MISS" => 0},
      %{:video_id => "3", "HIT" => 0, "MISS" => 3},
      %{:video_id => "4", "HIT" => 3, "MISS" => 0},
      %{:video_id => "5", "HIT" => 2, "MISS" => 1}
    ]
  end

  test "Formats TCP_hit_percentage into percent" do
    list = [
      %{:video_id => 1, "TCP_hit_percentage" => 1.0},
      %{:video_id => 2, "TCP_hit_percentage" => 1.0},
      %{:video_id => 3, "TCP_hit_percentage" => 0},
      %{:video_id => 4, "TCP_hit_percentage" => 1.0},
      %{:video_id => 5, "TCP_hit_percentage" => 0.75}
    ]
    result = integer_to_percent(list, "TCP_hit_percentage")
    assert result ==  [
      %{:video_id => 1, "TCP_hit_percentage" => "100%"},
      %{:video_id => 2, "TCP_hit_percentage" => "100%"},
      %{:video_id => 3, "TCP_hit_percentage" => "0%"},
      %{:video_id => 4, "TCP_hit_percentage" => "100%"},
      %{:video_id => 5, "TCP_hit_percentage" => "75%"}
    ]
  end

  test "Sort by field name" do
    # list = [
    #   %{:video_id => "9478", "TCP_hit_percentage" => "75%"},
    #   %{:video_id => "234567", "TCP_hit_percentage" => "100%"},
    #   %{:video_id => "009999", "TCP_hit_percentage" => "100%"},
    #   %{:video_id => "004567", "TCP_hit_percentage" => "100%"},
    #   %{:video_id => "123456", "TCP_hit_percentage" => "0%"}
    # ]
    # result = sort_by_field(list, :video_id)
    # assert result ==  [
    #   %{:video_id => "9478", "TCP_hit_percentage" => "75%"},
    #   %{:video_id => "004567", "TCP_hit_percentage" => "100%"},
    #   %{:video_id => "009999", "TCP_hit_percentage" => "100%"},
    #   %{:video_id => "123456", "TCP_hit_percentage" => "0%"},
    #   %{:video_id => "234567", "TCP_hit_percentage" => "100%"}
    # ]


    list = [
      %{:video_id => 9478, "TCP_hit_percentage" => "75%"},
      %{:video_id => 234567, "TCP_hit_percentage" => "100%"},
      %{:video_id => 9999, "TCP_hit_percentage" => "100%"},
      %{:video_id => 004567, "TCP_hit_percentage" => "100%"},
      %{:video_id => 123456, "TCP_hit_percentage" => "0%"},
      %{:video_id => 009899, "TCP_hit_percentage" => "100%"},
    ]
    result = sort_by_field(list, :video_id)
    assert result ==  [
      %{:video_id => 004567, "TCP_hit_percentage" => "100%"},
      %{:video_id => 9478, "TCP_hit_percentage" => "75%"},
      %{:video_id => 009899, "TCP_hit_percentage" => "100%"},
       %{:video_id => 9999, "TCP_hit_percentage" => "100%"},
      %{:video_id => 123456, "TCP_hit_percentage" => "0%"},
      %{:video_id => 234567, "TCP_hit_percentage" => "100%"}
    ]
  end
end