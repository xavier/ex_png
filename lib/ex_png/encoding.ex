defmodule ExPNG.Encoding do

  import ExPNG.Utils, only: [deflate: 1, crc32: 2]

  alias ExPNG.Chunks, as: Chunks

  # PNG
  @signature <<137, 80, 78, 71, 13, 10, 26, 10>>

  # 2^31 - 1
  @maximum_chunk_size 0x7fffffff

  @doc "Encodes the given Header chunk payload and pixel data into a PNG bitstream"
  def encode({header, image_data}) do
    encode_chunks([header|slice_image_data(image_data)], @signature)
  end

  # "Slices image data larger that the maximum chunk size"
  defp slice_image_data(image_data), do: _slice_image_data(image_data, [])
  defp _slice_image_data(<<chunk_data::binary-size(@maximum_chunk_size), image_data::binary>>, chunks), do: _slice_image_data(image_data, [chunk_data|chunks])
  defp _slice_image_data(<<image_data::binary>>, chunks), do: Enum.reverse([image_data|chunks])

  # Encodes a list of chunks into a binary stream
  defp encode_chunks([], stream), do: stream <> wrap_chunk(encode_chunk_payload(:end))
  defp encode_chunks([payload|payloads], stream), do: encode_chunks(payloads, stream <> wrap_chunk(encode_chunk_payload(payload)))

  # Wrap the given data into the PNG binary chunk format
  defp wrap_chunk({type, data}) do
    <<
      byte_size(data) :: unsigned-32,
      type :: binary-size(4),
      data :: binary,
      crc32(type, data) :: unsigned-32
    >>
  end

  # Header chunk encoder
  defp encode_chunk_payload(%Chunks.Header{width: _} = header) do
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

  # Image data chunk encoder
  defp encode_chunk_payload(<<image_data :: binary>>) do
    {"IDAT", deflate(image_data)}
  end

  # Terminal chunk encoder
  defp encode_chunk_payload(:end), do: {"IEND", <<>>}

end