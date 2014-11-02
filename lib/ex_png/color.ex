defmodule ExPNG.Color do

  def transparent do
    <<0, 0, 0, 0>>
  end

  def black(opacity \\ 255) do
    grayscale(0, opacity)
  end

  def white(opacity \\ 255) do
    grayscale(255, opacity)
  end

  def grayscale(tint, a \\ 255) do
    rgba(tint, tint, tint, a)
  end

  def rgb(r, g, b) do
    rgba(r, g, b, 255)
  end

  def rgba(r, g, b, a) do
    <<r, g, b, a>>
  end

  def red(<<r, _, _, _>>),   do: r
  def green(<<_, g, _, _>>), do: g
  def blue(<<_, _, b, _>>),  do: b
  def alpha(<<_, _, _, a>>), do: a

  @hex_rgb    ~r/\A\#?(?<r>[\da-f])(?<g>[\da-f])(?<b>[\da-f])\Z/i
  @hex_rrggbb ~r/\A\#?(?<r>[\da-f]{2})(?<g>[\da-f]{2})(?<b>[\da-f]{2})\Z/i


  def hex(string) do
    cond do
      captures = Regex.named_captures(@hex_rrggbb, string) ->
        %{"r" => r, "g" => g, "b" => b} = captures
        rgb(hex_to_dec(r), hex_to_dec(g), hex_to_dec(b))

      captures = Regex.named_captures(@hex_rgb, string) ->
        %{"r" => r, "g" => g, "b" => b} = captures
        rgb(hex_to_dec(r <> r), hex_to_dec(g <> g), hex_to_dec(b <> b))

      true ->
        :invalid_hex_string
    end
  end

  defp hex_to_dec(string) do
    string
    |> String.codepoints
    |> Enum.reduce(0, fn (d, acc) -> acc * 16 + hex_digit(d) end)
  end

  defp hex_digit("0"), do: 0
  defp hex_digit("1"), do: 1
  defp hex_digit("2"), do: 2
  defp hex_digit("3"), do: 3
  defp hex_digit("4"), do: 4
  defp hex_digit("5"), do: 5
  defp hex_digit("6"), do: 6
  defp hex_digit("7"), do: 7
  defp hex_digit("8"), do: 8
  defp hex_digit("9"), do: 9
  defp hex_digit("a"), do: 10
  defp hex_digit("A"), do: 10
  defp hex_digit("b"), do: 11
  defp hex_digit("B"), do: 11
  defp hex_digit("c"), do: 12
  defp hex_digit("C"), do: 12
  defp hex_digit("d"), do: 13
  defp hex_digit("D"), do: 13
  defp hex_digit("e"), do: 14
  defp hex_digit("E"), do: 14
  defp hex_digit("f"), do: 15
  defp hex_digit("F"), do: 15

end