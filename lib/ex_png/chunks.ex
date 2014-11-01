defmodule ExPNG.Chunks do

  # 'IHDR' => Header,
  # 'IEND' => End,
  # 'IDAT' => ImageData,
  # 'PLTE' => Palette,
  # 'tRNS' => Transparency,
  # 'tEXt' => Text,
  # 'zTXt' => CompressedText,
  # 'iTXt' => InternationalText,

  # color_type
  # Greyscale 0
  # Truecolour  2
  # Indexed-colour  3
  # Greyscale with alpha  4
  # Truecolour with alpha 6

  # interlace_method
  # None 0
  # Adam7 1

  # PNG
  @signature <<137, 80, 78, 71, 13, 10, 26, 10>>

  # 2^31 - 1
  @maximum_chunk_size 0x7fffffff

  defmodule Chunk do
    defstruct type: nil, length: nil, data: nil, payload: nil, crc: nil
  end

  defmodule Header do
    defstruct width: nil, height: nil, bit_depth: nil, color_type: nil, compression_method: nil, filter_method: nil, interlace_method: nil
  end

  @doc "Decodes a binary stream into a list of chunks"
  def decode(stream) do
    {:ok, stream} = verify_signature(stream)
    decode_chunks(stream, [])
  end

  @doc "Encodes the given Header chunk payload and pixel data into a PNG bitstream"
  def encode({header, image_data}) do
    encode_chunks([header|slice_image_data(image_data)], @signature)
  end

  @doc "Returns the header chunk for the given chunk list"
  def header([%Chunk{type: "IHDR"} = chunk|_]), do: chunk.payload
  def header([_|chunks]), do: header(chunks)
  def header([]), do: nil

  @doc "Returns the complete image data for the given chunk list"
  def image_data(chunks) do
    combine_image_data(chunks, <<>>)
  end

  @doc "Slices image data larger that the maximum chunk size"
  defp slice_image_data(image_data), do: _slice_image_data(image_data, [])
  defp _slice_image_data(<<chunk_data::binary-size(@maximum_chunk_size), image_data::binary>>, chunks), do: _slice_image_data(image_data, [chunk_data|chunks])
  defp _slice_image_data(<<image_data::binary>>, chunks), do: Enum.reverse([image_data|chunks])

  @doc "Combines multiple image data chunk payloads into a single binary"
  defp combine_image_data([%Chunk{type: "IDAT", payload: payload}|chunks], binary), do: combine_image_data(chunks, binary <> payload)
  defp combine_image_data([_|chunks], binary), do: combine_image_data(chunks, binary)
  defp combine_image_data([], binary), do: binary

  defp verify_signature(<<137, 80, 78, 71, 13, 10, 26, 10, stream::binary>>), do: {:ok, stream}
  defp verify_signature(stream), do: {:error, stream}

  defp crc_check(%Chunk{crc: crc} = chunk) do
    case crc32(chunk.type, chunk.data) do
      ^crc -> :ok
      _ -> nil
    end
  end

  defp decode_chunks(<<>>, chunks), do: Enum.reverse(chunks)
  defp decode_chunks(<<length::size(32), type::binary-size(4), stream::binary>>, chunks) do
    <<payload::binary-size(length), crc::size(32), stream::binary>> = stream
    chunk = %Chunk{type: type, length: length, data: payload, crc: crc}
    :ok = crc_check(chunk)
    decode_chunks(stream, [decode_chunk(chunk)|chunks])
  end

  defp encode_chunks([], stream), do: stream <> wrap_chunk(encode_chunk_payload(:end))
  defp encode_chunks([payload|payloads], stream), do: encode_chunks(payloads, stream <> wrap_chunk(encode_chunk_payload(payload)))

  def wrap_chunk({type, data}) do
    <<
      byte_size(data) :: unsigned-32,
      type :: binary-size(4),
      data :: binary,
      crc32(type, data) :: unsigned-32
    >>
  end

  defp encode_chunk_payload(%Header{width: _} = header) do
    payload = <<
      header.width :: unsigned-32,
      header.height :: unsigned-32,
      header.bit_depth :: unsigned-8,
      header.color_type :: unsigned-8,
      header.compression_method :: unsigned-8,
      header.filter_method :: unsigned-8,
      header.interlace_method :: unsigned-8
    >>
    {"IHDR", payload}
  end

  defp encode_chunk_payload(<<image_data :: binary>>) do
    {"IDAT", deflate(image_data)}
  end

  defp encode_chunk_payload(:end), do: {"IEND", <<>>}

  def decode_chunk(%Chunk{type: "IHDR", data: data} = chunk) do
    <<
      width::size(32),
      height::size(32),
      bit_depth::size(8),
      color_type::size(8),
      compression_method::size(8),
      filter_method::size(8),
      interlace_method::size(8),
    >> = data
    payload = %Header{
      width: width,
      height: height,
      bit_depth: bit_depth,
      color_type: color_type,
      compression_method: compression_method,
      filter_method: filter_method,
      interlace_method: interlace_method
    }
    %Chunk{chunk | payload: payload}
  end

  def decode_chunk(%Chunk{type: "IEND"} = chunk) do
    %Chunk{chunk | payload: nil}
  end

  def decode_chunk(%Chunk{type: "IDAT", data: data} = chunk) do
    %Chunk{chunk | payload: inflate(data)}
  end

  def decode_chunk(chunk), do: %Chunk{chunk | payload: :unsupported}

  #
  # Utility functions
  #

  defp crc32(type, data) do
    :erlang.crc32(:erlang.crc32(type), data)
  end

  defp inflate(compressed) do
    z = :zlib.open()
    :ok = :zlib.inflateInit(z)
    uncompressed = :zlib.inflate(z, compressed)
    :zlib.inflateEnd(z)
    :erlang.list_to_binary(uncompressed)
  end

  defp deflate(uncompressed) do
    z = :zlib.open()
    :ok = :zlib.deflateInit(z)
    compressed = :zlib.deflate(z, uncompressed, :finish)
    :zlib.deflateEnd(z)
    :erlang.list_to_binary(compressed)
  end

end
