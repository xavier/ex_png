#
# Run as:
#
#     mix run examples/mandelbrot.exs
#

defmodule Mandelbrot do

  require ExPNG.Color, as: Color

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


width = 1024
height = 768

path = Path.join([File.cwd!, "examples", "output", "mandelbrot.png"])

IO.puts "Writing to #{path}"

ExPNG.image(width, height)
|> Mandelbrot.draw
|> ExPNG.write(path)

