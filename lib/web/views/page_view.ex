defmodule Mobilizon.Web.PageView do
  @moduledoc """
  View for our webapp
  """

  use Mobilizon.Web, :view

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Conversations.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Resources.Resource
  alias Mobilizon.Tombstone

  alias Mobilizon.Service.Metadata
  alias Mobilizon.Service.Metadata.Instance

  alias Mobilizon.Federation.ActivityPub.Utils
  alias Mobilizon.Federation.ActivityStream.Convertible
  import Mobilizon.Web.Views.Utils

  def render("actor.activity-json", %{conn: %{assigns: %{object: %Actor{} = actor}}}) do
    actor
    |> Convertible.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("event.activity-json", %{conn: %{assigns: %{object: %Event{} = event}}}) do
    event
    |> Convertible.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("event.activity-json", %{conn: %{assigns: %{object: %Tombstone{} = event}}}) do
    event
    |> Convertible.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("comment.activity-json", %{conn: %{assigns: %{object: %Comment{} = comment}}}) do
    comment
    |> Convertible.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render("resource.activity-json", %{conn: %{assigns: %{object: %Resource{} = resource}}}) do
    resource
    |> Convertible.model_to_as()
    |> Map.merge(Utils.make_json_ld_header())
  end

  def render(page, %{object: object, conn: conn} = _assigns)
      when page in ["actor.html", "event.html", "comment.html"] do
    locale = get_locale(conn)
    tags = object |> Metadata.build_tags(locale)
    inject_tags(tags, locale)
  end

  def render("index.html", %{conn: conn}) do
    tags = Instance.build_tags()
    inject_tags(tags, get_locale(conn))
  end
end
