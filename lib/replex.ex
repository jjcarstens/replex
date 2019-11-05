defmodule Replex do
  @spec replay(String.t, number, list) :: :ok | {:error, ArgumentError.t} | {:error, RuntimeError.t}
  def replay(file, frequency, opts \\ []) do
    with {:ok, file} <- validate_file(file),
         {:ok, frequency} <- validate_frequency(frequency),
         {_output, 0} <- do_replay(file, frequency, opts)
    do
      :ok
    else
      {output, 1} -> {:error, %RuntimeError{message: "sendiq failed: #{output}"}}
      err -> {:error, err}
    end
  end

  @spec sendiq :: binary
  def sendiq() do
    Path.join(:code.priv_dir(:replex), "sendiq")
  end

  defp do_replay(file, frequency, opts) do
    args = [
      "-f", to_string(frequency),
      "-t", Keyword.get(opts, :iq_type, :u8) |> to_string,
      "-s", Keyword.get(opts, :sample_rate, 240_000) |> to_string,
      "-i", file
    ]

    System.cmd(sendiq(), args)
  end

  defp validate_file(file) when is_bitstring(file) do
    if File.exists?(file) do
      {:ok, file}
    else
      %RuntimeError{message: "file does not exist [#{file}]"}
    end
  end

  defp validate_file(_file) do
    %ArgumentError{message: "file must be a string"}
  end

  defp validate_frequency(frequency) when is_number(frequency) do
    {:ok, frequency}
  end

  defp validate_frequency(_freq) do
    %ArgumentError{message: "frequency must be a number"}
  end
end
