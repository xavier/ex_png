defmodule ExPNG.ColorTest do
  use ExUnit.Case
  alias ExPNG.Color, as: Color

  test "transparent" do
    assert <<0, 0, 0, 0>> == Color.transparent
  end

  test "RGB conversion" do
    assert <<11, 22, 33, 255>> == Color.rgb(11, 22, 33)
  end

  test "RGBA conversion" do
    assert <<11, 22, 33, 44>> == Color.rgba(11, 22, 33, 44)
  end

  test "grayscale" do
    assert <<13, 13, 13, 255>> == Color.grayscale(13)
  end

  test "grayscale with custom opacity" do
    assert <<13, 13, 13, 44>> == Color.grayscale(13, 44)
  end

  test "3 digits RGB hex conversion" do
    assert <<0xff, 0x33, 0xcc, 0xff>> == Color.hex("f3c")
  end

  test "3 digits RGB hex conversion with leading hash" do
    assert <<0xff, 0x33, 0xcc, 0xff>> == Color.hex("#f3c")
  end

  test "6 digits RGB hex conversion" do
    assert <<0x1a, 0xb2, 0x3c, 255>> == Color.hex("1AB23C")
  end

  test "6 digits RGB hex conversion with leading hash" do
    assert <<0x1a, 0xb2, 0x3c, 255>> == Color.hex("#1ab23c")
  end

  test "RGBA accessors" do
    rgba = Color.rgba(1, 2, 3, 4)
    assert 1 = Color.red(rgba)
    assert 2 = Color.green(rgba)
    assert 3 = Color.blue(rgba)
    assert 4 = Color.alpha(rgba)
  end

end
