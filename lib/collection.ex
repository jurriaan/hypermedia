defmodule Hypermedia.Collection do
  @moduledoc ~S"""
  HAL/JSON Collection module

  ## Usage

    iex> defmodule TestUserRepresenter do
    iex>   use Hypermedia.Representable
    iex>
    iex>   property :email
    iex> end
    iex> defmodule CollectionTestUserRepresenter do
    iex>   use Hypermedia.Collection
    iex>
    iex>   embed_as :users, TestUserRepresenter
    iex> end
    iex> Hypermedia.Collection.to_map([%{:email => "example@example.com"},%{:email => "foo@bar.com"}], CollectionTestUserRepresenter)
    %{"_embedded"=>%{"users"=>[%{"email"=>"example@example.com"},%{"email"=>"foo@bar.com"}]}}

  """

  # Callback invoked by `use`.
  #
  # For now it simply returns a quoted expression that
  # imports the module itself into the user code.
  @doc false
  defmacro __using__(_opts) do
    quote do
      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
      Module.register_attribute __MODULE__, :attributes, accumulate: true, persist: false
    end
  end

  @doc false
  defmacro __before_compile__(_) do
    quote do
      def to_map(model), do: unquote(__MODULE__).to_map(model, __MODULE__)
  def __attributes__, do: @attributes
    end
  end

  @doc ~S"""
  Defines the (singular) representer to use when interpreting each
  item in the list as a collection.

  ## Examples

    iex> defmodule TestRepresenter do
    iex>   use Hypermedia.Representable
    iex>
    iex>   property :test
    iex> end
    iex> defmodule TestCollectionRepresenter do
    iex>   use Hypermedia.Collection
    iex>
    iex>   embed_as :tests, TestRepresenter
    iex> end
    iex> Hypermedia.Collection.to_map([%{:test => true},%{:test => false}], TestCollectionRepresenter)
    %{"_embedded"=>%{"tests"=>[%{"test"=>true},%{"test"=>false}]}}

  """
  defmacro embed_as(name, presenter) do
    attribute = {:embed_as, name}

    quote do
      @attributes unquote(attribute)

      def unquote(method_name(attribute))(models) do
        Enum.map(models, fn(model) ->
          Hypermedia.Representable.to_map(model, unquote(presenter))
        end)
      end
    end
  end

  @doc ~S"""
  Get the link method name as an atom

  ## Examples

    iex> Hypermedia.Collection.method_name(:embed_as, :resources)
    :resources

    iex> Hypermedia.Collection.method_name(:embed_as, "resources")
    :resources

  """
  def method_name({type, name}), do: method_name(type, name)
  def method_name(:embed_as, name), do: String.to_atom("#{name}")

  def add_embed(map, embed, value) do
    embeds = Map.put(Map.get(map, "_embedded", %{}), to_string(embed), value)
    Map.put(map, "_embedded", embeds)
  end

  def to_map(collection, module) do
    Enum.reduce(module.__attributes__, Map.new, fn({type, key} = attr, map) ->
      process_attribute(map, attr, apply(module, method_name(type, key), [collection]))
    end)
  end

  @doc ~S"""
  Processes link options

  ## Examples

    iex> Hypermedia.Collection.process_attribute(%{}, [embed_as: :bar], [%{test: true}])
    %{"_embedded" => %{"bar" => [%{test: true}]}}

  """
  defp process_attribute(map, {:embed_as, key}, value), do: add_embed(map, key, value)
end
