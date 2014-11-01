defmodule ExPNG do

  def read(path) do
    path
    |> File.read!
    |> ExPNG.Chunks.decode
    |> ExPNG.Image.from_chunks
  end

end
