ExUnit.start()

defmodule Fixtures do

  def path(filename) do
    Path.join [File.cwd!, "test", "fixtures", filename]
  end

  def read(filename) do
    filename |> path |> File.read!
  end

end
