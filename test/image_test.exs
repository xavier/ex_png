defmodule ExPNG.ImageTest do
  use ExUnit.Case
  alias ExPNG.Image, as: Image
  alias ExPNG.Color, as: Color

  test "new image" do
    png = Image.new(2, 1, Color.transparent)
    assert 2 == png.width
    assert 1 == png.height
    assert <<0,0,0,0,0,0,0,0>> == png.pixels
  end

  test "set_pixel" do
    png = Image.new(1, 2, Color.transparent)
    png = Image.set_pixel(png, 1, 0, Color.white)
    assert <<0,0,0,0,255,255,255,255>> == png.pixels
  end

end
