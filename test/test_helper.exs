ExUnit.start()

defmodule Fixtures do

  def path(filename) do
    Path.join [File.cwd!, "test", "fixtures", filename]
  end

  def read(filename) do
    filename |> path |> File.read!
  end

end

defmodule StagingArea do

  @keep_files false

  def path(filename) do
    Path.join [File.cwd!, "test", "tmp", filename]
  end

  def list_files do
    path("*.png") |> Path.wildcard
  end

  def delete_files do
    unless @keep_files do
      list_files |> Enum.each(&File.rm/1)
    end
  end

end