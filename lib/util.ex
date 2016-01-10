defmodule Hypermedia.Util do
  @doc ~S"""
  Joins an base URL with a path

  ## Examples

      iex> Hypermedia.Util.uri_join("https://google.nl", "test")
      "https://google.nl/test"
      iex> Hypermedia.Util.uri_join("https://google.nl/", "/test")
      "https://google.nl/test"
      iex> Hypermedia.Util.uri_join("https://google.nl/subdir", "/test/path")
      "https://google.nl/test/path"
      iex> Hypermedia.Util.uri_join("https://google.nl/subdir", "test/path")
      "https://google.nl/subdir/test/path"
      iex> Hypermedia.Util.uri_join(URI.parse("https://google.nl/subdir"), "test/path")
      "https://google.nl/subdir/test/path"
  """
  def uri_join(base = %URI{path: base_path}, path), do: %{base | path: Path.absname(path, base_path || "/")} |> URI.to_string
  def uri_join(base, path), do: URI.parse(base) |> uri_join(path)
end
