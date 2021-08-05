defmodule DedupCsvTest do
  use ExUnit.Case
  doctest DedupCsv

  def getStream(string) do
    {:ok, stream} = string |> StringIO.open()
    stream |> IO.binstream(:line)
  end

  @header "FirstName,LastName,Email,Phone"

  test "removes duplicates" do
    input = """
    #{@header}
    Albert,Ortiz,Albert.Ortiz@gmail.com,235.908.1152
    albert,ortiz,albert.ortiz@gmail.com,235.908.5112
    Mary,Ortiz,mary.ortiz@me.com,(235) 908-1152
    """

    assert DedupCsv.process(:email, input |> getStream) |> Enum.join("") == """
    #{@header}
    Albert,Ortiz,Albert.Ortiz@gmail.com,235.908.1152
    Mary,Ortiz,mary.ortiz@me.com,(235) 908-1152
    """

    assert DedupCsv.process(:phone, input |> getStream) |> Enum.join("") == """
    #{@header}
    Albert,Ortiz,Albert.Ortiz@gmail.com,235.908.1152
    albert,ortiz,albert.ortiz@gmail.com,235.908.5112
    """

    assert DedupCsv.process(:email_or_phone, input |> getStream) |> Enum.join("") == """
    #{@header}
    Albert,Ortiz,Albert.Ortiz@gmail.com,235.908.1152
    """
  end

  test "shouldn't dedup on empty columns" do
    input = """
    #{@header}
    Natalie,Schuster,,448-778-3691
    Natalie,Schuster,,
    Natalie,Schuster,natalie@yahoo.com,
    """

    expected = """
    #{@header}
    Natalie,Schuster,,448-778-3691
    Natalie,Schuster,,
    Natalie,Schuster,natalie@yahoo.com,
    """

    assert DedupCsv.process(:email, input |> getStream) |> Enum.join("") == expected
    assert DedupCsv.process(:phone, input |> getStream) |> Enum.join("") == expected
    assert DedupCsv.process(:email_or_phone, input |> getStream) |> Enum.join("") == expected
  end

  test "if no headers, should return nothing" do
    input = """
    Natalie,Schuster,,448-778-3691
    Natalie,Schuster,,
    Natalie,Schuster,natalie@yahoo.com,
    """

    expected = """
    """

    assert DedupCsv.process(:email, input |> getStream) |> Enum.join("") == expected
    assert DedupCsv.process(:phone, input |> getStream) |> Enum.join("") == expected
    assert DedupCsv.process(:email_or_phone, input |> getStream) |> Enum.join("") == expected
  end

  # Test 1: no duplicates - should return everything as is
  # Test 5: missing values in some columns
  # Test 6: bad csv file entry
end
