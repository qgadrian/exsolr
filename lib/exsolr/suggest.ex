defmodule Exsolr.Suggest do
  @moduledoc """
  Provides search functions to Solr
  """

  require Logger

  alias Exsolr.Config
  alias Exsolr.HttpResponse

  @doc """
  Receives the query params, converts them to an url, queries a Solr suggestions and builds
  the response
  """
  def suggest(params) do
    params
    |> build_solr_query()
    |> do_suggest()
    |> extract_response()
  end

  @doc """
  Builds the solr url query. It will use the following default values if they
  are not specifier

  wt: "json"
  q: "*:*"
  start: 0
  rows: 10

  ## Examples

      iex> Exsolr.Searcher.build_solr_query(q: "roses", fq: ["blue", "violet"])
      "?wt=json&start=0&rows=10&q=roses&fq=blue&fq=violet"

      iex> Exsolr.Searcher.build_solr_query(q: "roses", fq: ["blue", "violet"], start: 0, rows: 10)
      "?wt=json&q=roses&fq=blue&fq=violet&start=0&rows=10"

      iex> Exsolr.Searcher.build_solr_query(q: "roses", fq: ["blue", "violet"], wt: "xml")
      "?start=0&rows=10&q=roses&fq=blue&fq=violet&wt=xml"

  """
  def build_solr_query(params) do
    "?" <> build_solr_query_params(params)
  end

  defp build_solr_query_params(params) do
    params
    |> add_default_params()
    |> Enum.map(fn {key, value} -> build_solr_query_parameter(key, value) end)
    |> Enum.join("&")
  end

  defp add_default_params(params) do
    default_parameters()
    |> Keyword.merge(params)
  end

  defp default_parameters do
    [wt: "json", q: "*:*", start: 0, rows: 10]
  end

  defp build_solr_query_parameter(_, []), do: nil

  defp build_solr_query_parameter(key, [head | tail]) do
    [build_solr_query_parameter(key, head), build_solr_query_parameter(key, tail)]
    |> Enum.reject(fn x -> x == nil end)
    |> Enum.join("&")
  end

  defp build_solr_query_parameter(:q, value) do
    "q=#{URI.encode_www_form(value)}"
  end

  defp build_solr_query_parameter(:cursorMark, value) do
    ["cursorMark", value]
    |> Enum.join("=")
    |> URI.encode()
    |> String.replace("+", "%2B")
  end

  defp build_solr_query_parameter(key, value) do
    require Logger
    Logger.debug(fn -> key end)
    Logger.debug(fn -> value end)

    [Atom.to_string(key), value]
    |> Enum.join("=")
    |> URI.encode()
  end

  def do_suggest(solr_query) do
    solr_query
    |> build_solr_url()
    |> HTTPoison.get()
    |> HttpResponse.body()
  end

  defp build_solr_url(solr_query) do
    url = Config.suggest_url() <> solr_query
    Logger.debug(fn -> url end)
    url
  end

  defp extract_response(solr_response) do
    case solr_response do
      {:ok, solr_response} ->
        case parse_response(solr_response) do
          {:ok, solr_response} ->
            {:ok, solr_response}

          {:error, reason} ->
            Logger.error(fn -> "Solr response parse: #{inspect(reason)}" end)
            {:error, reason}
        end

      {:error, reason, message} ->
        Logger.error(fn -> "Solr request failed: #{inspect(reason)}" end)
        {:error, reason, message}

      {:error, reason} ->
        Logger.error(fn -> "Solr request failed: #{inspect(reason)}" end)
        {:error, reason}
    end
  end

  defp parse_response(solr_response) do
    case Poison.decode(solr_response) do
      {:ok, %{"suggest" => suggesters}} ->
        {:ok, suggesters}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp extract_mlt_result(mlt) do
    result = for k <- Map.keys(mlt), do: get_in(mlt, [k, "docs"])
    result |> List.flatten()
  end
end
