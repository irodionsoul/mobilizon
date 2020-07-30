defmodule Mobilizon.GraphQL.Schema.Actors.GroupType do
  @moduledoc """
  Schema representation for Group.
  """

  use Absinthe.Schema.Notation

  alias Mobilizon.GraphQL.Resolvers.{Discussion, Group, Member, Post, Resource, Todos}
  alias Mobilizon.GraphQL.Schema

  import_types(Schema.Actors.MemberType)

  @desc """
  Represents a group of actors
  """
  object :group do
    interfaces([:actor])

    field(:id, :id, description: "Internal ID for this group")
    field(:url, :string, description: "The ActivityPub actor's URL")
    field(:type, :actor_type, description: "The type of Actor (Person, Group,…)")
    field(:name, :string, description: "The actor's displayed name")
    field(:domain, :string, description: "The actor's domain if (null if it's this instance)")
    field(:local, :boolean, description: "If the actor is from this instance")
    field(:summary, :string, description: "The actor's summary")
    field(:preferred_username, :string, description: "The actor's preferred username")

    field(:manually_approves_followers, :boolean,
      description: "Whether the actors manually approves followers"
    )

    field(:suspended, :boolean, description: "If the actor is suspended")

    field(:avatar, :picture, description: "The actor's avatar picture")
    field(:banner, :picture, description: "The actor's banner picture")

    # These one should have a privacy setting
    field(:following, list_of(:follower), description: "List of followings")
    field(:followers, list_of(:follower), description: "List of followers")
    field(:followersCount, :integer, description: "Number of followers for this actor")
    field(:followingCount, :integer, description: "Number of actors following this actor")

    # This one should have a privacy setting
    field :organized_events, :paginated_event_list do
      resolve(&Group.find_events_for_group/3)
      description("A list of the events this actor has organized")
    end

    field :discussions, :paginated_discussion_list do
      resolve(&Discussion.find_discussions_for_actor/3)
      description("A list of the discussions for this group")
    end

    field(:types, :group_type, description: "The type of group : Group, Community,…")

    field(:openness, :openness,
      description: "Whether the group is opened to all or has restricted access"
    )

    field :members, :paginated_member_list do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      arg(:roles, :string, default_value: "")
      resolve(&Member.find_members_for_group/3)
      description("A paginated list of group members")
    end

    field :resources, :paginated_resource_list do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Resource.find_resources_for_group/3)
      description("A paginated list of the resources this group has")
    end

    field :posts, :paginated_post_list do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Post.find_posts_for_group/3)
      description("A paginated list of the posts this group has")
    end

    field :todo_lists, :paginated_todo_list_list do
      resolve(&Todos.find_todo_lists_for_group/3)
      description("A paginated list of the todo lists this group has")
    end
  end

  @desc """
  The types of Group that exist
  """
  enum :group_type do
    value(:group, description: "A private group of persons")
    value(:community, description: "A public group of many actors")
  end

  @desc """
  Describes how an actor is opened to follows
  """
  enum :openness do
    value(:invite_only, description: "The actor can only be followed by invitation")

    value(:moderated, description: "The actor needs to accept the following before it's effective")

    value(:open, description: "The actor is open to followings")
  end

  object :paginated_group_list do
    field(:elements, list_of(:group), description: "A list of groups")
    field(:total, :integer, description: "The total number of elements in the list")
  end

  @desc "The list of visibility options for a group"
  enum :group_visibility do
    value(:public, description: "Publicly listed and federated")
    value(:unlisted, description: "Visible only to people with the link - or invited")
  end

  object :group_queries do
    @desc "Get all groups"
    field :groups, :paginated_group_list do
      arg(:page, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Group.list_groups/3)
    end

    @desc "Get a group by its preferred username"
    field :group, :group do
      arg(:preferred_username, non_null(:string))
      resolve(&Group.find_group/3)
    end
  end

  object :group_mutations do
    @desc "Create a group"
    field :create_group, :group do
      arg(:preferred_username, non_null(:string), description: "The name for the group")

      arg(:creator_actor_id, non_null(:id), description: "The identity that creates the group")

      arg(:name, :string, description: "The displayed name for the group")
      arg(:summary, :string, description: "The summary for the group", default_value: "")

      arg(:visibility, :group_visibility,
        description: "The visibility for the group",
        default_value: :public
      )

      arg(:avatar, :picture_input,
        description:
          "The avatar for the group, either as an object or directly the ID of an existing Picture"
      )

      arg(:banner, :picture_input,
        description:
          "The banner for the group, either as an object or directly the ID of an existing Picture"
      )

      resolve(&Group.create_group/3)
    end

    @desc "Update a group"
    field :update_group, :group do
      arg(:id, non_null(:id), description: "The group ID")

      arg(:name, :string, description: "The displayed name for the group")
      arg(:summary, :string, description: "The summary for the group", default_value: "")

      arg(:avatar, :picture_input,
        description:
          "The avatar for the group, either as an object or directly the ID of an existing Picture"
      )

      arg(:banner, :picture_input,
        description:
          "The banner for the group, either as an object or directly the ID of an existing Picture"
      )

      resolve(&Group.update_group/3)
    end

    @desc "Delete a group"
    field :delete_group, :deleted_object do
      arg(:group_id, non_null(:id))
      arg(:actor_id, non_null(:id))

      resolve(&Group.delete_group/3)
    end
  end
end
