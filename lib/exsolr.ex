defmodule Exsolr.Client do
  @moduledoc """
  Behaviour module for Exsolr client
  """

  @callback info() :: Map.t()
  @callback get(Keyword.t()) :: Map.t()
  @callback suggest(Keyword.t()) :: Map.t()
  @callback more_like_this(Keyword.t()) :: Map.t()
  @callback add(Map.t()) :: Atom.t()
  @callback commit() :: Atom.t()
  @callback delete_by_id(any()) :: Atom.t()
  @callback delete_all() :: Atom.t()
end

defmodule Exsolr do
  @moduledoc """
  Solr wrapper made in Elixir.
  """

  alias Exsolr.{Config, Indexer, Searcher, Suggest, MoreLikeThis}

  @behaviour Exsolr.Client

  @doc """
  Returns a map containing the solr connection info

  ## Examples

      iex> Exsolr.info
      %{hostname: "localhost", port: 8983, core: "elixir_test"}
  """
  def info do
    Config.info()
  end

  @doc """
  Send a search request to Solr.

  ## Example

      iex> Exsolr.get(q: "roses", fq: ["blue", "violet"])
      :tbd

      iex> Exsolr.get(q: "red roses", defType: "disMax")
      :tbd
  """
  def get(query_params) do
    Searcher.get(query_params)
  end

  @doc """
  Send a more like this (mlt) request to Solr.

  ## Example

      iex> Exsolr.more_like_this(q: "roses", mlt.fl: ["color", "height"])
      :tbd

      iex> Exsolr.more_like_this(q: "red roses", rows: 10)
      :tbd
  """
  def more_like_this(query_params) do
    MoreLikeThis.more_like_this(query_params)
  end

  @doc """
  Send a search request to Solr.

  ## Example

      iex> Exsolr.suggest("suggest.q": "roses", "suggest.dictionary": "suggestDictionary")
      :tbd
  """
  def suggest(query_params) do
    Suggest.suggest(query_params)
  end

  @doc """
  Adds the `document` to Solr.

  ## Example

      iex> Exsolr.add(%{id: 1, price: 1.00})
      :tbd
  """
  def add(document) do
    Indexer.add(document)
  end

  @doc """
  Commits the pending changes to Solr
  """
  def commit do
    Indexer.commit()
  end

  @doc """
  Delete the document with id `id` from the solr index
  """
  def delete_by_id(id) do
    Indexer.delete_by_id(id)
  end

  @doc """
  Delete all the documents from the Solr index

  https://wiki.apache.org/solr/FAQ#How_can_I_delete_all_documents_from_my_index.3F
  """
  def delete_all do
    Indexer.delete_all()
  end
end
