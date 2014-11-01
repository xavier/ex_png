defmodule ExPNG do

  def image(width, height) do
    ExPNG.Image.new(width, height)
  end

  def image(width, height, background_color) do
    ExPNG.Image.new(width, height, background_color)
  end

  def read(path) do
    path
    |> File.read!
    |> decode
  end

  def write(image, path) do
    {:ok, file} = File.open path, [:write]
    IO.binwrite(file, encode(image))
  end

  def decode(stream) do
    stream
    |> ExPNG.Chunks.decode
    |> ExPNG.Image.from_chunks
  end

  def encode(image) do
    image
    |> ExPNG.Image.to_chunks
    |> ExPNG.Chunks.encode
  end

end
