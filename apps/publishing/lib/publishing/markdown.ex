defmodule Publishing.Markdown do
  @moduledoc """
  Module for handling raw markdown texts.
  """

  @doc """
  Transform markdown into HMTL performing additional mutations.

  ## Features
  * Removes the first `#` heading
  * Add `language-none` to inline and code blocks.

  Example:
      iex> parse("# title")
      ""

      iex> parse("## title")
      "<h2>\\ntitle</h2>\\n"

      iex> parse("`some code`")
      "<p>\\n<code class=\\"language-none\\">some code</code></p>\\n"

      iex> parse("```\\nsome code\\n```")
      "<pre><code class=\\"language-none\\">some code</code></pre>\\n"
  """
  @spec parse(String.t()) :: list
  def parse(markdown) do
    markdown
    |> to_ast()
    |> remove_heading()
    |> add_code_class()
    |> Earmark.Transform.transform()
  end

  @doc """
  Returns the markdown's main title or the given `default` (optional).

  Examples:
      iex> get_heading("# Hello World!\\nLorem ipsum...")
      "Hello World!"

      iex> get_heading("Lorem ipsum dolor sit amet...")
      ""

      iex> get_heading("Lorem ipsum dolor sit amet...", "Untitled")
      "Untitled"
  """
  @spec get_heading(String.t()) :: String.t()
  def get_heading(content, default \\ "") when is_binary(content) do
    with {:ok, ast, _} <- EarmarkParser.as_ast(content),
         [{"h1", _, [title], _} | _tail] when is_binary(title) <- ast do
      title
    else
      _ -> default
    end
  end

  defp to_ast(markdown) do
    {:ok, ast, _} = EarmarkParser.as_ast(markdown, code_class_prefix: "language-")

    ast
  end

  defp remove_heading([{"h1", _, [_title], _} | tail]), do: tail
  defp remove_heading(ast), do: ast

  defp add_code_class(ast) do
    Earmark.Transform.map_ast(ast, fn
      {"code", [], [content], %{}} ->
        {"code", [{"class", "language-none"}], [content], %{}}

      {"code", [{"class", "inline"}], [content], %{}} ->
        {"code", [{"class", "language-none"}], [content], %{}}

      tag ->
        tag
    end)
  end
end
