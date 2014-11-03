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
    defstruct type: nil, length: nil, payload: nil, crc: nil
  end

  defmodule Header do
    defstruct width: nil, height: nil, bit_depth: nil, color_type: nil, compression_method: nil, filter_method: nil, interlace_method: nil
  end

  defmodule InternationalText do
    defstruct keyword: nil, language_tag: nil, translated_keyword: nil, text: nil
  end

  defmodule StandardRGB do
    defstruct rendering_intent: nil
  end

  #
  # Public API
  #

  @doc "Decodes a binary stream into a list of chunks"
  def decode(stream) do
    {:ok, stream} = verify_signature(stream)
    decode_chunks(stream)
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
    combine_image_data(chunks)
  end

  #
  # Decoder
  #

  defp verify_signature(<<137, 80, 78, 71, 13, 10, 26, 10, stream::binary>>), do: {:ok, stream}
  defp verify_signature(stream), do: {:error, stream}

  defp crc_check(type, data, crc) do
    case crc32(type, data) do
      ^crc -> :ok
      _ -> nil
    end
  end

  @doc "Combines multiple image data chunk payloads into a single binary"
  defp combine_image_data(chunks), do: _combine_image_data(chunks, <<>>)
  defp _combine_image_data([%Chunk{type: "IDAT", payload: payload}|chunks], binary), do: _combine_image_data(chunks, binary <> payload)
  defp _combine_image_data([_|chunks], binary), do: _combine_image_data(chunks, binary)
  defp _combine_image_data([], binary), do: binary

  defp decode_chunks(stream), do: _decode_chunks(stream, nil, [])
  defp _decode_chunks(<<>>, _, chunks), do: Enum.reverse(chunks)

  # First chunk, we expect the header
  defp _decode_chunks(<<length::unsigned-32, stream::binary>>, nil, chunks) do
    {%Chunk{type: "IHDR"} = chunk, data, stream} = unwrap_chunk(length, stream)
    header_chunk = decode_chunk(chunk, data, nil)
    _decode_chunks(stream, header_chunk.payload, [header_chunk|chunks])
  end

  # Subsequent chunks, we have the header
  defp _decode_chunks(<<length::unsigned-32, stream::binary>>, header, chunks) when header != nil do
    {chunk, data, stream} = unwrap_chunk(length, stream)
    _decode_chunks(stream, header, [decode_chunk(chunk, data, header)|chunks])
  end

  defp unwrap_chunk(length, stream) do
    <<type::binary-size(4), payload::binary-size(length), crc::unsigned-32, stream::binary>> = stream
    chunk = %Chunk{type: type, length: length}
    :ok = crc_check(type, payload, crc)
    {chunk, payload, stream}
  end

  defp decode_chunk(%Chunk{type: "IHDR"} = chunk, data, nil) do
    <<
      width::unsigned-32,
      height::unsigned-32,
      bit_depth::unsigned-8,
      color_type::unsigned-8,
      compression_method::unsigned-8,
      filter_method::unsigned-8,
      interlace_method::unsigned-8,
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

  defp decode_chunk(%Chunk{type: "IEND"} = chunk, _, _) do
    %Chunk{chunk | payload: nil}
  end

  defp decode_chunk(%Chunk{type: "IDAT"} = chunk, data, %Header{compression_method: 0}) do
    %Chunk{chunk | payload: inflate(data)}
  end

  defp decode_chunk(%Chunk{type: "iTXt"} = chunk, data, _) do
    {keyword, data} = null_terminated(data)
    <<compression::binary-size(2), data :: binary>> = data
    {language_tag, data} = null_terminated(data)
    {translated_keyword, data} = null_terminated(data)

    text = case compression do
      <<0, 0>> -> data
      <<1, 0>> -> deflate(data)
      true     -> :unsupported_compression
    end

    payload = %InternationalText{
      keyword: keyword,
      language_tag: language_tag,
      translated_keyword: translated_keyword,
      text: text
    }

    %Chunk{chunk | payload: payload}
  end

  defp decode_chunk(%Chunk{type: "sRGB"} = chunk, <<rendering_intent_value :: unsigned-8>>, _) do
    rendering_intent = case rendering_intent_value do
      0    -> :perceptual
      1    -> :relative_colorimetric
      2    -> :saturation
      3    -> :absolute_colorimetric
      true -> :unknown_rendering_intent
    end
    %Chunk{chunk | payload: %StandardRGB{rendering_intent: rendering_intent}}
  end

  defp decode_chunk(chunk, _, _), do: %Chunk{chunk | payload: :unsupported}

  defp null_terminated(string), do: _null_terminated(string, <<>>)
  defp _null_terminated(<<>>, match), do: {match, <<>>}
  defp _null_terminated(<<0, string :: binary>>, match), do: {match, string}
  defp _null_terminated(<<c, string :: binary>>, match), do: _null_terminated(string, match <> <<c>>)

  #
  # Encoder
  #

  @doc "Slices image data larger that the maximum chunk size"
  defp slice_image_data(image_data), do: _slice_image_data(image_data, [])
  defp _slice_image_data(<<chunk_data::binary-size(@maximum_chunk_size), image_data::binary>>, chunks), do: _slice_image_data(image_data, [chunk_data|chunks])
  defp _slice_image_data(<<image_data::binary>>, chunks), do: Enum.reverse([image_data|chunks])

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
