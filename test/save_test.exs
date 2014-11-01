defmodule ExPNG.SaveTest do
  use ExUnit.Case

  alias ExPNG.Color, as: Color
  alias ExPNG.Image, as: Image

  def create_test_image(width, height) do
    ExPNG.image(width, height, Color.transparent)
    |> Image.put_pixel(0, 0, Color.red)
    |> Image.put_pixel(width-1, 0, Color.green)
    |> Image.put_pixel(width-1, height-1, Color.blue)
    |> Image.put_pixel(0, height-1, Color.black)
  end

  defmodule Mandelbrot do

    # Obviously impairs the test speed but I couldn't resist :)

    require Bitwise

    @max_iterations 1000

    def draw(image) do
      scale_point = scaling_function(-2..2, -1.5..1.5, image.width, image.height)
      pixels = for y <- 0..(image.height-1), x <- 0..(image.width-1), into: <<>> do
        {sx, sy} = scale_point.(x, y)
        iteration = mandelbrot(sx, sy)
        tint = 255-round(iteration / @max_iterations * 255)
        if tint > 250 do
          r = Bitwise.band(Bitwise.bxor(x, y), 0xff)
          g = 0
          b = Bitwise.band(Bitwise.bor(div(x, 2), div(y, 2)), 0xff)
          Color.rgb(r, g, b)
        else
          Color.grayscale(tint)
        end
      end
      %{image | pixels: pixels}
    end

    defp scaling_function(x1..x2, y1..y2, width, height) do
      x_scale = abs(x1 - x2) / width
      y_scale = abs(y1 - y2) / height
      fn (x, y) ->
        {x1 + (((2*x)-1)*0.5)*x_scale, y1 + (((2*y)-1)*0.5)*y_scale}
      end
    end

    defp mandelbrot(x, y) do
      mandelbrot(x, y, 0, 0, 0)
    end

    defp mandelbrot(x0, y0, x, y, iter)
      when iter < @max_iterations and (x*x + y*y < 4), do:
        mandelbrot(x0, y0, x*x - y*y + x0, 2 *x*y + y0, iter + 1)

    defp mandelbrot(_, _, _, _, iter), do: iter

  end

  setup do
    on_exit fn -> StagingArea.delete_files end
  end

  test "encodes a simple true color image with a test pattern" do
    test_image = create_test_image(8, 8)
    encoded = ExPNG.encode(test_image)
    png = ExPNG.decode(encoded)
    assert {8, 8} == Image.size(png)
    assert Color.red == Image.get_pixel(png, 0, 0)
    assert Color.green == Image.get_pixel(png, 7, 0)
    assert Color.blue == Image.get_pixel(png, 7, 7)
    assert Color.black == Image.get_pixel(png, 0, 7)
  end

  test "save a complex true color images" do
    width = 640
    height = 480
    path = StagingArea.path("mandelbrot.png")
    ExPNG.image(width, height)
    |> Mandelbrot.draw
    |> ExPNG.write(path)
    img = ExPNG.read(path)
    assert {width, height} == Image.size(img)
  end

end
