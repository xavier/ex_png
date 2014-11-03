defmodule ExPNG.SaveTest do
  use ExUnit.Case

  alias ExPNG.Color, as: Color
  alias ExPNG.Image, as: Image

  @test_pattern_top_left     Color.rgb(255, 0, 0)
  @test_pattern_top_right    Color.rgb(0, 255, 0)
  @test_pattern_bottom_left  Color.rgb(0, 0, 255)
  @test_pattern_bottom_right Color.rgb(0, 0, 0)

  def create_test_pattern(width, height) do
    ExPNG.image(width, height, Color.transparent)
    |> Image.set_pixel(0, 0, @test_pattern_top_left)
    |> Image.set_pixel(width-1, 0, @test_pattern_top_right)
    |> Image.set_pixel(width-1, height-1, @test_pattern_bottom_right)
    |> Image.set_pixel(0, height-1, @test_pattern_bottom_left)
  end

  setup do
    on_exit fn -> StagingArea.delete_files end
  end

  test "encodes a simple true color image with a test pattern" do
    test_pattern = create_test_pattern(8, 8)
    encoded = ExPNG.encode(test_pattern)
    png = ExPNG.decode(encoded)
    assert {8, 8} == Image.size(png)
    assert @test_pattern_top_left == Image.get_pixel(png, 0, 0)
    assert @test_pattern_top_right == Image.get_pixel(png, 7, 0)
    assert @test_pattern_bottom_right == Image.get_pixel(png, 7, 7)
    assert @test_pattern_bottom_left == Image.get_pixel(png, 0, 7)
  end

end
