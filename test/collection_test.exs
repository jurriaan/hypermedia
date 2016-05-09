defmodule CollectionTest do
  use ExUnit.Case, async: true
  doctest Hypermedia.Collection

  defmodule UserTestRepresenter do
    use Hypermedia.Representable

    property :email
  end

  defmodule CollectionTestRepresenter do
    use Hypermedia.Collection

    embed_as :users, UserTestRepresenter
  end

  test "collection works for embed" do
    assert Hypermedia.Collection.to_map([%{:email => "example@example.com"},%{:email => "foo@bar.com"}], CollectionTestRepresenter) == %{"_embedded" => %{"users" => [%{"email" => "example@example.com"}, %{"email" => "foo@bar.com"}]}}
  end
end
