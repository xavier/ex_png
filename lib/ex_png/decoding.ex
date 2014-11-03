defmodule ExPNG.Decoding do

  import ExPNG.Utils, only: [inflate: 1, deflate: 1, crc32: 2]

  alias ExPNG.Chunks, as: Chunks

  @doc "Decodes a binary stream into a list of chunks"
  def decode(stream) do
    {:ok, stream} = verify_signature(stream)
    decode_chunks(stream)
  end

  #
  #
  #

  defp verify_signature(<<137, 80, 78, 71, 13, 10, 26, 10, stream::binary>>), do: {:ok, stream}
  defp verify_signature(stream), do: {:error, stream}

  defp crc_check(type, data, crc) do
    case crc32(type, data) do
      ^crc -> :ok
      _ -> nil
    end
  end

  defp decode_chunks(stream), do: _decode_chunks(stream, nil, [])
  defp _decode_chunks(<<>>, _, chunks), do: Enum.reverse(chunks)

  # First chunk, we expect the header
  defp _decode_chunks(<<length::unsigned-32, stream::binary>>, nil, chunks) do
    {%Chunks.Chunk{type: "IHDR"} = chunk, data, stream} = unwrap_chunk(length, stream)
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
    chunk = %Chunks.Chunk{type: type, length: length}
    :ok = crc_check(type, payload, crc)
    {chunk, payload, stream}
  end

  defp decode_chunk(%Chunks.Chunk{type: "IHDR"} = chunk, data, nil) do
    <<
      width::unsigned-32,
      height::unsigned-32,
      bit_depth::unsigned-8,
      color_type::unsigned-8,
      compression_method::unsigned-8,
      filter_method::unsigned-8,
      interlace_method::unsigned-8,
    >> = data
    payload = %Chunks.Header{
      width: width,
      height: height,
      bit_depth: bit_depth,
      color_type: color_type,
      compression_method: compression_method,
      filter_method: filter_method,
      interlace_method: interlace_method
    }
    %Chunks.Chunk{chunk | payload: payload}
  end

  defp decode_chunk(%Chunks.Chunk{type: "IEND"} = chunk, _, _) do
    %Chunks.Chunk{chunk | payload: nil}
  end

  defp decode_chunk(%Chunks.Chunk{type: "IDAT"} = chunk, data, %Chunks.Header{compression_method: 0}) do
    %Chunks.Chunk{chunk | payload: inflate(data)}
  end

  defp decode_chunk(%Chunks.Chunk{type: "tEXt"} = chunk, data, _) do
    {keyword, text} = null_terminated(data)
    %Chunks.Chunk{chunk | payload: %Chunks.Text{keyword: keyword, text: text}}
  end

  defp decode_chunk(%Chunks.Chunk{type: "zTXt"} = chunk, data, _) do
    {keyword, data} = null_terminated(data)
    text = case data do
      <<0, compressed :: binary>>
        -> inflate(compressed)
      _
        -> :unsupported_compression
    end
    %Chunks.Chunk{chunk | payload: %Chunks.Text{keyword: keyword, text: text}}
  end

  defp decode_chunk(%Chunks.Chunk{type: "iTXt"} = chunk, data, _) do
    {keyword, data} = null_terminated(data)
    <<compression::binary-size(2), data :: binary>> = data
    {language_tag, data} = null_terminated(data)
    {translated_keyword, data} = null_terminated(data)

    text = case compression do
      <<0, 0>>
        -> data
      <<1, 0>>
        -> deflate(data)
      _
        -> :unsupported_compression
    end

    payload = %Chunks.InternationalText{
      keyword: keyword,
      language_tag: language_tag,
      translated_keyword: translated_keyword,
      text: text
    }

    %Chunks.Chunk{chunk | payload: payload}
  end

  defp decode_chunk(%Chunks.Chunk{type: "sRGB"} = chunk, <<rendering_intent_value :: unsigned-8>>, _) do
    rendering_intent = case rendering_intent_value do
      0 -> :perceptual
      1 -> :relative_colorimetric
      2 -> :saturation
      3 -> :absolute_colorimetric
      _ -> :unknown_rendering_intent
    end
    %Chunks.Chunk{chunk | payload: %Chunks.StandardRGB{rendering_intent: rendering_intent}}
  end

  defp decode_chunk(%Chunks.Chunk{type: "pHYs"} = chunk, data, _) do
    <<x :: unsigned-32, y :: unsigned-32, unit_specifier :: unsigned-8>> = data
    unit = case unit_specifier do
      1 -> :m
      _ -> :unsupported_unit
    end
    %Chunks.Chunk{chunk | payload: %Chunks.PhysicalPixelDimensions{x: x, y: y, unit: unit}}
  end

  defp decode_chunk(chunk, _, _), do: %Chunks.Chunk{chunk | payload: :unsupported}

  defp null_terminated(string), do: _null_terminated(string, <<>>)
  defp _null_terminated(<<>>, match), do: {match, <<>>}
  defp _null_terminated(<<0, string :: binary>>, match), do: {match, string}
  defp _null_terminated(<<c, string :: binary>>, match), do: _null_terminated(string, match <> <<c>>)

end