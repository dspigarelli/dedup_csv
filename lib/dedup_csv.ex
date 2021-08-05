defmodule DedupCsv do

  @moduledoc """
  Takes a CSV file with headers "FirstName,LastName,Email,Phone" and then dedups
  the rows based on whether the email, phone, or either matches. Only the digits
  in phone numbers are evaluated for duplicates, and email addresses are lowercased
  and trimmed before being evaluated as duplicates
  """
  def main(argv) do
    argv
    |> parse_args
    |> process(IO.stream(:stdio, :line))
    |> Enum.each(&IO.write(&1))
  end

  @doc """
  De-dups a stream of CSV either by :email, :phone, or :email_or_phone. Prints a help
  message for any other input.
  """
  def process(:help, _) do
    IO.puts """
    usage: dedup_csv [ email | phone | email_or_phone ] < file.csv
    """
    System.halt(0)
  end

  def process(:email, stream) do
    stream
    |> decodeCSV
    |> Enum.reduce({%{}, []}, fn

      %{"Email" => email} = row, accum -> email |> sanitize_email |> dedup_value(row, accum)

      _, accum -> accum # the file doesn't have headers; skip everything

    end)
    |> encodeCSV
  end

  def process(:phone, stream) do
    stream
    |> decodeCSV
    |> Enum.reduce({%{}, []}, fn

      %{"Phone" => phone} = row, accum -> phone |> sanitize_phone |> dedup_value(row, accum)

      _, accum -> accum # the file doesn't have headers; skip everything

    end)
    |> encodeCSV
  end

  def process(:email_or_phone, stream) do
    stream
    |> decodeCSV
    |> Enum.reduce({%{}, []}, fn

      %{ "Phone" => phone, "Email" => email } = row, {map, rows} ->
        phone = phone |> sanitize_phone
        email = email |> sanitize_email

        newMap = map
        |> Map.put(phone, true)
        |> Map.put(email, true)

        cond do
          phone == "" or email == "" -> { newMap, [row | rows] }
          Map.has_key?(map, phone) or Map.has_key?(map, email) -> { newMap, rows }
          true -> { newMap, [row | rows]}
        end

      _, accum -> accum # the file doesn't have headers; skip everything

    end)
    |> encodeCSV
  end

  defp dedup_value(value, row, {map, rows}) do
    newMap = map |> Map.put(value, true)
    if value == "" or !Map.has_key?(map, value) do
      { newMap, [ row | rows ]}
    else
      { newMap, rows }
    end
  end

  defp sanitize_phone(phone) when is_bitstring(phone), do: phone |> String.replace(~r/[^\d]/, "")
  defp sanitize_phone(_), do: ""

  defp sanitize_email(email) when is_bitstring(email), do: email |> String.downcase |> String.trim
  defp sanitize_email(_), do: ""

  defp decodeCSV(stream) do
    stream
    |> CSV.decode(headers: true)
    |> Enum.filter(fn {result, _} -> result == :ok end)
    |> Enum.map(fn {_, person} -> person end)
  end

  defp encodeCSV(rows) do
    rows
    |> elem(1)
    |> Enum.reverse
    |> CSV.encode(headers: ["FirstName", "LastName", "Email", "Phone"], delimiter: "\n")
  end

  defp parse_args(argv) do
    OptionParser.parse(argv, switches: [
      help: :boolean,
    ], aliases: [h: :help])
    |> elem(1)
    |> parse_arguments()
  end

  defp parse_arguments(["email"]), do: :email
  defp parse_arguments(["phone"]), do: :phone
  defp parse_arguments(["email_or_phone"]), do: :email_or_phone
  defp parse_arguments(_), do: :help
end
