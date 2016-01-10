defmodule RepresentableTest do
  use ExUnit.Case, async: true
  doctest Hypermedia.Representable

  defmodule PropTest do
    use Hypermedia.Representable

    property :one
    property :two
    property :three

    link :self, do: "/test"
  end

  test "representable works for properties" do
    assert PropTest.to_map(%{one: true, three: 23.5}) == %{"one" => true, "three" => 23.5, "_links" => %{"self" => %{"href" => "https://example.org/test"}}}
    assert PropTest.to_map(%{one: 1, two: 2, three: 3}) == %{"one" => 1, "two" => 2, "three" => 3, "_links" => %{"self" => %{"href" => "https://example.org/test"}}}
    assert PropTest.to_map(%{}) == %{"_links" => %{"self" => %{"href" => "https://example.org/test"}}}
  end

  defmodule LinkTest do
    use Hypermedia.Representable

    link :resources, title: fn r -> "Title: #{r.prop}" end do
      "/resources"
    end

    link :resource, templated: true do
      "/resource/{id}"
    end

    link :title, title: "I do have a title" do
      "/title"
    end

    link :prop do
      "/prop/#{represented.prop}"
    end

    link :self, do: "/api"
  end

  test "representable works for links" do
    assert LinkTest.to_map(%{:prop => "value"}) == %{"_links" => %{"self" => %{"href" => "https://example.org/api"},
                                                                 "title" => %{"href" => "https://example.org/title", "title" => "I do have a title"},
                                                                 "prop" => %{"href" => "https://example.org/prop/value"},
                                                                 "resources" => %{"href" => "https://example.org/resources", "title" => "Title: value"},
                                                                 "resource" => %{"href" => "https://example.org/resource/{id}", "templated" => true}}}
  end
end
