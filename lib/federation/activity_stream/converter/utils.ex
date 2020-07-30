defmodule Mobilizon.Federation.ActivityStream.Converter.Utils do
  @moduledoc """
  Various utils for converters.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.Tag
  alias Mobilizon.Mention
  alias Mobilizon.Storage.Repo

  alias Mobilizon.Federation.ActivityPub

  alias Mobilizon.Web.Endpoint

  require Logger

  @spec fetch_tags([String.t()]) :: [Tag.t()]
  def fetch_tags(tags) when is_list(tags) do
    Logger.debug("fetching tags")
    Logger.debug(inspect(tags))

    tags |> Enum.flat_map(&fetch_tag/1) |> Enum.uniq() |> Enum.map(&existing_tag_or_data/1)
  end

  def fetch_tags(_), do: []

  @spec fetch_mentions([map()]) :: [map()]
  def fetch_mentions(mentions) when is_list(mentions) do
    Logger.debug("fetching mentions")

    Enum.reduce(mentions, [], fn mention, acc -> create_mention(mention, acc) end)
  end

  def fetch_mentions(_), do: []

  def fetch_address(%{id: id}) do
    with {id, ""} <- Integer.parse(id), do: %{id: id}
  end

  def fetch_address(address) when is_map(address) do
    address
  end

  @spec build_tags([Tag.t()]) :: [map()]
  def build_tags(tags) do
    Enum.map(tags, fn %Tag{} = tag ->
      %{
        "href" => Endpoint.url() <> "/tags/#{tag.slug}",
        "name" => "##{tag.title}",
        "type" => "Hashtag"
      }
    end)
  end

  def build_mentions(mentions) do
    Enum.map(mentions, fn %Mention{} = mention ->
      if Ecto.assoc_loaded?(mention.actor) do
        build_mention(mention.actor)
      else
        build_mention(Repo.preload(mention, [:actor]).actor)
      end
    end)
  end

  defp build_mention(%Actor{} = actor) do
    %{
      "href" => actor.url,
      "name" => "@#{Actor.preferred_username_and_domain(actor)}",
      "type" => "Mention"
    }
  end

  defp fetch_tag(%{title: title}), do: [title]

  defp fetch_tag(tag) when is_map(tag) do
    case tag["type"] do
      "Hashtag" ->
        [tag_without_hash(tag["name"])]

      _err ->
        []
    end
  end

  defp fetch_tag(tag) when is_bitstring(tag), do: [tag_without_hash(tag)]

  defp tag_without_hash("#" <> tag_title), do: tag_title
  defp tag_without_hash(tag_title), do: tag_title

  defp existing_tag_or_data(tag_title) do
    case Events.get_tag_by_title(tag_title) do
      %Tag{} = tag -> %{title: tag.title, id: tag.id}
      nil -> %{title: tag_title}
    end
  end

  @spec create_mention(map(), list()) :: list()
  defp create_mention(%Actor{id: actor_id} = _mention, acc) do
    acc ++ [%{actor_id: actor_id}]
  end

  @spec create_mention(map(), list()) :: list()
  defp create_mention(mention, acc) when is_map(mention) do
    with true <- mention["type"] == "Mention",
         {:ok, %Actor{id: actor_id}} <- ActivityPub.get_or_fetch_actor_by_url(mention["href"]) do
      acc ++ [%{actor_id: actor_id}]
    else
      _err ->
        acc
    end
  end

  @spec create_mention({String.t(), map()}, list()) :: list()
  defp create_mention({_, mention}, acc) when is_map(mention) do
    create_mention(mention, acc)
  end

  @spec maybe_fetch_actor_and_attributed_to_id(map()) :: {Actor.t() | nil, Actor.t() | nil}
  def maybe_fetch_actor_and_attributed_to_id(%{
        "actor" => actor_url,
        "attributedTo" => attributed_to_url
      })
      when is_nil(attributed_to_url) do
    {fetch_actor(actor_url), nil}
  end

  @spec maybe_fetch_actor_and_attributed_to_id(map()) :: {Actor.t() | nil, Actor.t() | nil}
  def maybe_fetch_actor_and_attributed_to_id(%{
        "actor" => actor_url,
        "attributedTo" => attributed_to_url
      })
      when is_nil(actor_url) do
    {fetch_actor(attributed_to_url), nil}
  end

  # Only when both actor and attributedTo fields are both filled is when we can return both
  def maybe_fetch_actor_and_attributed_to_id(%{
        "actor" => actor_url,
        "attributedTo" => attributed_to_url
      })
      when actor_url != attributed_to_url do
    with actor <- fetch_actor(actor_url),
         attributed_to <- fetch_actor(attributed_to_url) do
      {actor, attributed_to}
    end
  end

  # If we only have attributedTo and no actor, take attributedTo as the actor
  def maybe_fetch_actor_and_attributed_to_id(%{
        "attributedTo" => attributed_to_url
      }) do
    {fetch_actor(attributed_to_url), nil}
  end

  def maybe_fetch_actor_and_attributed_to_id(_), do: {nil, nil}

  @spec fetch_actor(String.t()) :: Actor.t()
  defp fetch_actor(actor_url) do
    with {:ok, %Actor{suspended: false} = actor} <-
           ActivityPub.get_or_fetch_actor_by_url(actor_url) do
      actor
    end
  end
end
