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

end