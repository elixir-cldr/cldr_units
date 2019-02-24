defmodule Mix.Tasks.Cldr.Unit.Download do
  @moduledoc """
  Downloads the latest unit conversion table for Cldr.Unit
  """

  use Mix.Task
  require Logger

  @shortdoc "Download Unit Conversion Table"

  @doc false
  def run(_) do
    Application.ensure_all_started(:inets)
    Application.ensure_all_started(:ssl)

    Enum.each(required_files(), &download_file/1)
  end

  defp required_files do
    [
      {"https://raw.githubusercontent.com/kipcole9/cldr_units/master/priv/conversion_factors.json",
        data_path("conversion_factors.json")},
    ]
  end

  defp download_file({url, destination}) do
    url = String.to_charlist(url)

    case :httpc.request(url) do
      {:ok, {{_version, 200, 'OK'}, _headers, body}} ->
        destination
        |> File.write!(:erlang.list_to_binary(body))

        Logger.info("Downloaded #{inspect(url)} to #{inspect(destination)}")
        {:ok, destination}

      {_, {{_version, code, message}, _headers, _body}} ->
        Logger.error(
          "Failed to download #{inspect(url)}. " <> "HTTP Error: (#{code}) #{inspect(message)}"
        )

        {:error, code}

      {:error, {:failed_connect, [{_, {host, _port}}, {_, _, sys_message}]}} ->
        Logger.error(
          "Failed to connect to #{inspect(host)} to download " <>
            " #{inspect(url)}. Reason: #{inspect(sys_message)}"
        )

        {:error, sys_message}
    end
  end

  defp data_path(filename) do
    Path.join("./priv", filename)
  end
end

