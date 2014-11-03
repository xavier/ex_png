defmodule ExPNG.LoadTest do
  use ExUnit.Case

  alias ExPNG.Color, as: Color
  alias ExPNG.Image, as: Image

  test "loads a simple 8x8 true color image with a test pattern" do
    png = ExPNG.read(Fixtures.path("test_8x8.png"))
    assert {8, 8} == Image.size(png)
    assert Color.hex("#FF0000") == Image.get_pixel(png, 0, 0)
    assert Color.hex("#00FF00") == Image.get_pixel(png, 7, 0)
    assert Color.hex("#0000FF") == Image.get_pixel(png, 7, 7)
    assert Color.hex("#000000") == Image.get_pixel(png, 0, 7)
  end

  test "loads a true color image" do
    png = ExPNG.read(Fixtures.path("test_truecolor.png"))
    assert {256, 256} == Image.size(png)
  end

  test "loads iTXt chunks" do
    stream = File.read!(Fixtures.path("test_8x8.png"))
    chunks = ExPNG.Chunks.decode(stream)
    itxt   = Enum.find(chunks, fn (%{type: t}) -> t == "iTXt" end)

    assert "XML:com.adobe.xmp" == itxt.payload.keyword
    assert String.starts_with?(itxt.payload.text, "<x:xmpmeta")
    assert String.ends_with?(itxt.payload.text, "</x:xmpmeta>\n")
  end

  test "loads sRGB chunks" do
    stream = File.read!(Fixtures.path("test_8x8.png"))
    chunks = ExPNG.Chunks.decode(stream)
    srgb   = Enum.find(chunks, fn (%{type: t}) -> t == "sRGB" end)

    assert :perceptual == srgb.payload.rendering_intent
  end

end
