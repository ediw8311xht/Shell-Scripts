#!/bin/elixir

defmodule WordList do
  defstruct words: MapSet.new()

  def new(), do: new([])

  def new(word_list) when is_list(word_list) do
    %WordList{words: MapSet.new(word_list)}
  end

  def new(file) when is_binary(file) do
    %WordList{
      words:
        readfile(file)
        |> String.split("\n")
        |> Stream.map(&String.trim/1)
        |> Stream.filter(&(String.length(&1) >= 1))
        |> MapSet.new()
    }
  end

  def capitalize(string) when is_binary(string) do
    <<first_letter::utf8, rest::binary>> = string
    String.upcase(<<first_letter>>) <> rest
  end

  def pick_random(%WordList{words: words}), do: Enum.random(words)

  def generate_username(word_list = %WordList{}, length: length, capital: capital) do
    Enum.reduce(1..length, "", fn _, acc ->
      if capital do
        acc <> WordList.capitalize(WordList.pick_random(word_list))
      else
        acc <> WordList.pick_random(word_list)
      end
    end)
  end

  def readfile(file) do
    case File.read(file) do
      {:ok, ofile} ->
        ofile

      {:error, _} ->
        IO.puts("Couldn't open '#{file}'.")
        exit(:normal)
    end
  end
end

defmodule Main do
  @file_path Path.absname(__DIR__)
  @default_length 3
  @default_file "#{@file_path}/Resources/Txt/top_1000_nouns.txt"
  @default_capital true
  @keys [length: @default_length, file: @default_file, capital: @default_capital]
  @handle {&Main.convert_int/1, &Function.identity/1, &String.to_atom/1}
  def convert_int(string) do
    case Integer.parse(string) do
      {a, ""} -> a
      :error -> exit(:normal)
    end
  end

  def handle_args([]), do: @keys

  def handle_args(args) do
    Enum.reduce(0..min(length(args) - 1, 1), @keys, fn x, acc ->
      arg = Enum.at(args, x)
      {key, _val} = Enum.at(acc, x)
      replace = {key, elem(@handle, x).(arg)}
      List.replace_at(acc, x, replace)
    end)
  end

  def main(args) do
    handle_args(args)
    |> Main.gen_user()
  end

  def gen_user(length: length, file: file, capital: capital) do
    WordList.new(file)
    |> WordList.generate_username(length: length, capital: capital)
    |> IO.puts()
  end
end

Main.main(System.argv())
