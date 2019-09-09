defmodule Mobilizon.Application do
  @moduledoc """
  The Mobilizon application
  """

  use Application

  import Cachex.Spec

  alias Mobilizon.Config
  alias Mobilizon.Service.Export.{Feed, ICalendar}

  @name Mix.Project.config()[:name]
  @version Mix.Project.config()[:version]

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Mobilizon.Storage.Repo, []),
      # Start the endpoint when the application starts
      supervisor(MobilizonWeb.Endpoint, []),
      # Start your own worker by calling: Mobilizon.Worker.start_link(arg1, arg2, arg3)
      # worker(Mobilizon.Worker, [arg1, arg2, arg3]),
      worker(
        Cachex,
        [
          :feed,
          [
            limit: 2500,
            expiration:
              expiration(
                default: :timer.minutes(60),
                interval: :timer.seconds(60)
              ),
            fallback: fallback(default: &Feed.create_cache/1)
          ]
        ],
        id: :cache_feed
      ),
      worker(
        Cachex,
        [
          :ics,
          [
            limit: 2500,
            expiration:
              expiration(
                default: :timer.minutes(60),
                interval: :timer.seconds(60)
              ),
            fallback: fallback(default: &ICalendar.create_cache/1)
          ]
        ],
        id: :cache_ics
      ),
      worker(
        Cachex,
        [
          :activity_pub,
          [
            limit: 2500,
            expiration:
              expiration(
                default: :timer.minutes(3),
                interval: :timer.seconds(15)
              )
          ]
        ],
        id: :cache_activity_pub
      ),
      worker(Guardian.DB.Token.SweeperServer, []),
      worker(Mobilizon.Service.Federator, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mobilizon.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MobilizonWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def named_version, do: @name <> " " <> @version

  def user_agent do
    info = "#{MobilizonWeb.Endpoint.url()} <#{Config.get([:instance, :email], "")}>"

    named_version() <> "; " <> info
  end
end
