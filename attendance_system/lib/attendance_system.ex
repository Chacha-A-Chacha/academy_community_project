# lib/attendance_system/application.ex
defmodule AttendanceSystem.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      AttendanceSystemWeb.Telemetry,
      # Start the Ecto repository
      AttendanceSystem.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: AttendanceSystem.PubSub},
      # Start Finch
      {Finch, name: AttendanceSystem.Finch},
      # Start Oban (only in non-test environments)
      {Oban, Application.fetch_env!(:attendance_system, Oban)},
      # Start the Endpoint (http/https)
      AttendanceSystemWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: AttendanceSystem.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    AttendanceSystemWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
