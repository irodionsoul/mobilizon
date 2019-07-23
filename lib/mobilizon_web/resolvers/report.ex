defmodule MobilizonWeb.Resolvers.Report do
  @moduledoc """
  Handles the report-related GraphQL calls
  """
  alias Mobilizon.Reports
  alias Mobilizon.Reports.{Report, Note}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Actors
  alias Mobilizon.Users.User
  alias MobilizonWeb.API.Reports, as: ReportsAPI
  import Mobilizon.Users.Guards

  def list_reports(_parent, %{page: page, limit: limit}, %{
        context: %{current_user: %User{role: role}}
      })
      when is_moderator(role) do
    {:ok, Mobilizon.Reports.list_reports(page, limit)}
  end

  def list_reports(_parent, _args, _resolution) do
    {:error, "You need to be logged-in and a moderator to list reports"}
  end

  def get_report(_parent, %{id: id}, %{
        context: %{current_user: %User{role: role}}
      })
      when is_moderator(role) do
    {:ok, Mobilizon.Reports.get_report(id)}
  end

  def get_report(_parent, _args, _resolution) do
    {:error, "You need to be logged-in and a moderator to view a report"}
  end

  @doc """
  Create a report
  """
  def create_report(
        _parent,
        %{reporter_actor_id: reporter_actor_id} = args,
        %{context: %{current_user: user}} = _resolution
      ) do
    with {:is_owned, true, _} <- User.owns_actor(user, reporter_actor_id),
         {:ok, _, %Report{} = report} <- ReportsAPI.report(args) do
      {:ok, report}
    else
      {:is_owned, false} ->
        {:error, "Reporter actor id is not owned by authenticated user"}

      _err ->
        {:error, "Error while saving report"}
    end
  end

  def create_report(_parent, _args, _resolution) do
    {:error, "You need to be logged-in to create reports"}
  end

  @doc """
  Update a report's status
  """
  def update_report(
        _parent,
        %{report_id: report_id, moderator_id: moderator_id, status: status},
        %{
          context: %{current_user: %User{role: role} = user}
        }
      )
      when is_moderator(role) do
    with {:is_owned, true, _} <- User.owns_actor(user, moderator_id),
         %Actor{} = actor <- Actors.get_actor!(moderator_id),
         %Report{} = report <- Mobilizon.Reports.get_report(report_id),
         {:ok, %Report{} = report} <-
           MobilizonWeb.API.Reports.update_report_status(actor, report, status) do
      {:ok, report}
    else
      {:is_owned, false} ->
        {:error, "Actor id is not owned by authenticated user"}

      _err ->
        {:error, "Error while updating report"}
    end
  end

  def update_report(_parent, _args, _resolution) do
    {:error, "You need to be logged-in and a moderator to update a report"}
  end

  def create_report_note(
        _parent,
        %{report_id: report_id, moderator_id: moderator_id, content: content},
        %{
          context: %{current_user: %User{role: role} = user}
        }
      )
      when is_moderator(role) do
    with {:is_owned, true, _} <- User.owns_actor(user, moderator_id),
         %Report{} = report <- Reports.get_report(report_id),
         %Actor{} = moderator <- Actors.get_local_actor_with_everything(moderator_id),
         {:ok, %Note{} = note} <-
           MobilizonWeb.API.Reports.create_report_note(report, moderator, content) do
      {:ok, note}
    end
  end

  def delete_report_note(_parent, %{note_id: note_id, moderator_id: moderator_id}, %{
        context: %{current_user: %User{role: role} = user}
      })
      when is_moderator(role) do
    with {:is_owned, true, _} <- User.owns_actor(user, moderator_id),
         %Note{} = note <- Reports.get_note(note_id),
         %Actor{} = moderator <- Actors.get_local_actor_with_everything(moderator_id),
         {:ok, %Note{} = note} <-
           MobilizonWeb.API.Reports.delete_report_note(note, moderator) do
      {:ok, %{id: note.id}}
    end
  end
end
