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

  defmodule Chunk do
    defstruct type: nil, length: nil, data: nil, payload: nil, crc: nil
  end

  def decode(stream) do
    {:ok, stream} = verify_signature(stream)
    decode_chunks(stream, [])
  end

  def header([%Chunk{type: "IHDR"} = chunk|_]), do: chunk.payload
  def header([_|chunks]), do: header(chunks)
  def header([]), do: nil

  def image_data(chunks) do
    combine_image_data(chunks, <<>>)
  end

  defp combine_image_data([%Chunk{type: "IDAT", payload: payload}|chunks], binary), do: combine_image_data(chunks, binary <> payload)
  defp combine_image_data([_|chunks], binary), do: combine_image_data(chunks, binary)
  defp combine_image_data([], binary), do: binary

  defp verify_signature(<<137, 80, 78, 71, 13, 10, 26, 10, stream::binary>>), do: {:ok, stream}
  defp verify_signature(stream), do: {:error, stream}

  defp decode_chunks(<<length::size(32), type::binary-size(4), stream::binary>>, chunks) do
    <<payload::binary-size(length), crc::size(32), stream::binary>> = stream
    chunk = %Chunk{type: type, length: length, data: payload, crc: crc}
    :ok = crc_check(chunk)
    decode_chunks(stream, [decode_chunk(chunk)|chunks])
  end

  defp decode_chunks("", chunks), do: Enum.reverse(chunks)

  defp crc_check(%Chunk{crc: crc} = chunk) do
    case chunk_crc(chunk) do
      ^crc -> :ok
      _ -> nil
    end
  end

  defp chunk_crc(%Chunk{type: type, data: data}) do
    :erlang.crc32(:erlang.crc32(type), data)
  end

  defmodule IHDR do
    defstruct width: nil, height: nil, bit_depth: nil, color_type: nil, compression_method: nil, filter_method: nil, interlace_method: nil
  end

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
    payload = %IHDR{
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

  defp inflate(compressed) do
    z = :zlib.open()
    :ok = :zlib.inflateInit(z)
    iolist = :zlib.inflate(z, compressed)
    :zlib.inflateEnd(z)
    :erlang.list_to_binary(iolist)
  end

end
