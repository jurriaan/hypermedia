defmodule Hypermedia.Representable do
  alias Hypermedia.Util

  @moduledoc ~S"""
  HAL/JSON Representable module

  ## Usage

      iex> defmodule TestRepresenter do
      iex>   use Hypermedia.Representable
      iex>   property :test
      iex>   link :self, do: "/"
      iex> end
      iex> Hypermedia.Representable.to_map(%{test: true}, TestRepresenter)
      %{ "_links" => %{"self" => %{"href" => "https://example.org/"}}, "test" => true }

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
  Defines a property on the representer

  ## Examples

     iex> defmodule PropertyDocTest do
     iex>   use Hypermedia.Representable
     iex>   property :test
     iex> end
     iex> Hypermedia.Representable.to_map(%{test: true}, PropertyDocTest)
     %{"test" => true}

  """
  defmacro property(name) do
    attribute = {:property, name}

    quote do
      @attributes unquote(attribute)

      def unquote(method_name(attribute))(model) do
        Map.get(model, unquote(name))
      end
    end
  end

  @doc ~S"""
  Defines a link on the representer

  ## Examples

      iex> defmodule LinkDocTest do
      iex>   use Hypermedia.Representable
      iex>   link :self, do: "/#{represented.test}"
      iex> end
      iex> Hypermedia.Representable.to_map(%{test: "yup"}, LinkDocTest)
      %{ "_links" => %{"self" => %{"href" => "https://example.org/yup"}}}

  """
  defmacro link(name, opts \\ [], do: block) do
    attribute = {:link, name}

    quote do
      @attributes unquote(attribute)

      def unquote(method_name(attribute))(var!(represented)) do
        unquote(__MODULE__).process_link_options(%{"href" => unquote(block)}, unquote(opts), var!(represented))
      end
    end
  end

  @doc ~S"""
  Processes link options

  ## Examples

      iex> Hypermedia.Representable.process_link_options(%{}, [foo: :bar], %{})
      %{}

      iex> Hypermedia.Representable.process_link_options(%{"href" => "/{id}"}, [templated: true], %{})
      %{"href" => "/{id}", "templated" => true}

      iex> Hypermedia.Representable.process_link_options(%{"href" => "/{id}"}, [type: fn r -> r.type end], %{:type => "text/plain"})
      %{"href" => "/{id}", "type" => "text/plain"}
  """
  def process_link_options(map, [], _represented), do: map
  def process_link_options(map, [head | tail], represented), do: process_link_options(link_option(map, head, represented), tail, represented)
  defp link_option(map, {key, fun}, represented) when is_function(fun), do: link_option(map, {key, fun.(represented)}, represented)
  defp link_option(map, {:templated, value}, _), do: Map.put(map, "templated", value)
  defp link_option(map, {:title, value}, _), do: Map.put(map, "title", value)
  defp link_option(map, {:name, value}, _), do: Map.put(map, "name", value)
  defp link_option(map, {:type, value}, _), do: Map.put(map, "type", value)
  defp link_option(map, _, _), do: map

  @doc ~S"""
  Get the link method name as an atom

  ## Examples

      iex> Hypermedia.Representable.method_name(:link, :resource)
      :__link__resource

      iex> Hypermedia.Representable.method_name(:link, "resources")
      :__link__resources

      iex> Hypermedia.Representable.method_name(:property, :title)
      :title

      iex> Hypermedia.Representable.method_name(:property, "title")
      :title

  """
  def method_name({type, name}), do: method_name(type, name)
  def method_name(:link, name), do: String.to_atom("__link__#{name}")
  def method_name(:property, name), do: String.to_atom("#{name}")

  @doc ~S"""
  Adds a link to a map

  ## Examples

      iex> map = Hypermedia.Representable.add_link(%{}, :self, %{"href" => "/api"})
      %{ "_links" => %{"self" => %{"href" => "https://example.org/api"}} }
      iex> Hypermedia.Representable.add_link(map, :next, %{"href" => "/api?p=2", "title" => "Page 2"})
      %{ "_links" => %{"self" => %{"href" => "https://example.org/api"}, "next" => %{"href" => "https://example.org/api?p=2", "title" => "Page 2"}} }

  """
  def add_link(map, link, value = %{"href" => href}) do
    base = Application.get_env(:hypermedia, :base_uri)
    uri = Util.uri_join(base, href)
    links = Map.put(Map.get(map, "_links", %{}), to_string(link), %{value | "href" => uri})
    Map.put(map, "_links", links)
  end

  @doc ~S"""
  Represent `model` using representer `module`

  ## Examples

      iex> defmodule Test do
      iex>   use Hypermedia.Representable
      iex>   property :test
      iex>   link :self, do: "/"
      iex> end
      iex> Hypermedia.Representable.to_map(%{test: true}, Test)
      %{ "_links" => %{"self" => %{"href" => "https://example.org/"}}, "test" => true }

  """
  def to_map(model, module) do
    Enum.reduce(module.__attributes__, Map.new, fn({type, key} = attr, map) ->
      process_attribute(map, attr, apply(module, method_name(type, key), [model]))
    end)
  end

  defp process_attribute(map, _, nil), do: map
  defp process_attribute(map, {:link, key}, value), do: add_link(map, key, value)
  defp process_attribute(map, {:property, key}, value), do: Map.put(map, to_string(key), value)
end
