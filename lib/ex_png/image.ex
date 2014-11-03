defmodule ExPNG.Image do

  alias __MODULE__, as: Image

  defstruct width: 0, height: 0, pixels: <<>>

  def new(width, height) do
    new(width, height, ExPNG.Color.transparent)
  end

  def new(width, height, background_color) do
    %Image{width: width, height: height, pixels: String.duplicate(background_color, width*height)}
  end

  def from_chunks(chunks) do
    header = ExPNG.Chunks.header(chunks)
    :ok = ensure_features_supported(header)
    image_data = strip_scan_line_filter_byte(ExPNG.Chunks.image_data(chunks), header.width * 4, <<>>)
    %Image{width: header.width, height: header.height, pixels: image_data}
  end

  defp ensure_features_supported(%ExPNG.Chunks.Header{bit_depth: 8, color_type: 6, compression_method: 0, interlace_method: 0}), do: :ok
  defp ensure_features_supported(_), do: nil

  defp strip_scan_line_filter_byte(<<>>, _, output), do: output
  defp strip_scan_line_filter_byte(image_data, scan_line_width, output) do
    <<_, scan_line::binary-size(scan_line_width), next_scan_lines::binary>> = image_data
    strip_scan_line_filter_byte(next_scan_lines, scan_line_width, output <> scan_line)
  end

  defp add_scan_line_filter_byte(<<>>, _, output), do: output
  defp add_scan_line_filter_byte(image_data, scan_line_width, output) do
    <<scan_line::binary-size(scan_line_width), next_scan_lines::binary>> = image_data
    add_scan_line_filter_byte(next_scan_lines, scan_line_width, output <> <<0>> <> scan_line)
  end

  # This will probably have to change but let's keep it simple for now
  def to_chunks(image) do
    {to_header_chunk(image), add_scan_line_filter_byte(image.pixels, image.width * 4, <<>>)}
  end

  def to_header_chunk(image) do
    %ExPNG.Chunks.Header{
      width: image.width,
      height: image.height,
      bit_depth: 8,
      color_type: 6,
      compression_method: 0,
      interlace_method: 0,
      filter_method: 0,
    }
  end

  def size(%Image{width: w, height: h}) do
    {w, h}
  end

  # FIXME this is probably incredibly inefficient
  def set_pixel(image, x, y, color) do
    offset = pixel_offset(image, x, y)
    <<before::binary-size(offset), _::binary-size(4), rest::binary>> = image.pixels
    %Image{image | pixels: (before <> color <> rest)}
  end

  def get_pixel(image, x, y) do
    offset = pixel_offset(image, x, y)
    <<_::binary-size(offset), pixel::binary-size(4), _::binary >> = image.pixels
    pixel
  end

  defp pixel_offset(image, x, y) do
    (y * image.width + x) * 4
  end

end