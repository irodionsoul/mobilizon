defmodule MobilizonWeb.Schema.CommentType do
  @moduledoc """
  Schema representation for Comment
  """
  use Absinthe.Schema.Notation

  @desc "A comment"
  object :comment do
    field(:uuid, :uuid)
    field(:url, :string)
    field(:local, :boolean)
    field(:visibility, :comment_visibility)
    field(:text, :string)
    field(:primaryLanguage, :string)
    field(:replies, list_of(:comment))
    field(:threadLanguages, non_null(list_of(:string)))
  end

  @desc "The list of visibility options for a comment"
  enum :comment_visibility do
    value(:public, description: "Publically listed and federated. Can be shared.")
    value(:unlisted, description: "Visible only to people with the link - or invited")

    value(:private,
      description: "Visible only to people members of the group or followers of the person"
    )

    value(:moderated, description: "Visible only after a moderator accepted")
    value(:invite, description: "visible only to people invited")
  end
end
