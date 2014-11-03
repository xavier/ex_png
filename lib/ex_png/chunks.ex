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

  import ExPNG.Utils, only: [deflate: 1, crc32: 2]

  defmodule Chunk do
    defstruct type: nil, length: nil, payload: nil, crc: nil
  end

  defmodule Header do
    defstruct width: nil, height: nil, bit_depth: nil, color_type: nil, compression_method: nil, filter_method: nil, interlace_method: nil
  end

  defmodule Text do
    defstruct keyword: nil, text: nil
  end

  defmodule InternationalText do
    defstruct keyword: nil, language_tag: nil, translated_keyword: nil, text: nil
  end

  defmodule StandardRGB do
    defstruct rendering_intent: nil
  end

  defmodule PhysicalPixelDimensions do
    defstruct x: nil, y: nil, unit: nil
  end

  @doc "Decodes a binary stream into a list of chunks"
  def decode(stream) do
    ExPNG.Decoding.decode(stream)
  end

  @doc "Encodes the given Header chunk payload and pixel data into a PNG bitstream"
  def encode({header, image_data}) do
    ExPNG.Encoding.encode({header, image_data})
  end

  @doc "Returns the header chunk for the given chunk list"
  def header([%Chunk{type: "IHDR"} = chunk|_]), do: chunk.payload
  def header([_|chunks]), do: header(chunks)
  def header([]), do: nil

  @doc "Returns the complete image data for the given chunk list"
  def image_data(chunks) do
    combine_image_data(chunks)
  end

  # "Combines multiple image data chunk payloads into a single binary"
  defp combine_image_data(chunks), do: _combine_image_data(chunks, <<>>)
  defp _combine_image_data([%Chunk{type: "IDAT", payload: payload}|chunks], binary), do: _combine_image_data(chunks, binary <> payload)
  defp _combine_image_data([_|chunks], binary), do: _combine_image_data(chunks, binary)
  defp _combine_image_data([], binary), do: binary

end
