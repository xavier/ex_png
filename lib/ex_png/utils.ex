defmodule ExPNG.Utils do

  def crc32(type, data) do
    :erlang.crc32(:erlang.crc32(type), data)
  end

  def inflate(compressed) do
    z = :zlib.open()
    :ok = :zlib.inflateInit(z)
    uncompressed = :zlib.inflate(z, compressed)
    :zlib.inflateEnd(z)
    :erlang.list_to_binary(uncompressed)
  end

  def deflate(uncompressed) do
    z = :zlib.open()
    :ok = :zlib.deflateInit(z)
    compressed = :zlib.deflate(z, uncompressed, :finish)
    :zlib.deflateEnd(z)
    :erlang.list_to_binary(compressed)
  end

  @doc """

    Extracts a null-terminated string from the given binary, returns

    iex> {_match, string} = ExPNG.Utils.null_terminated("ABC\0DEF\0\0XYZ")
    {"ABC", "DEF\0\0XYZ"}
    iex> {_match, string} = ExPNG.Utils.null_terminated(string)
    {"DEF", "\0XYZ"}
    iex> {_match, string} = ExPNG.Utils.null_terminated(string)
    {"", "XYZ"}
    iex> {_match, string} = ExPNG.Utils.null_terminated(string)
    {"XYZ", ""}
    iex> {_match, _string} = ExPNG.Utils.null_terminated(string)
    {"", ""}

  """

  def null_terminated(string), do: null_terminated(string, <<>>)

  defp null_terminated(<<>>, match), do: {match, <<>>}
  defp null_terminated(<<0, string :: binary>>, match), do: {match, string}
  defp null_terminated(<<c, string :: binary>>, match), do: null_terminated(string, match <> <<c>>)

end