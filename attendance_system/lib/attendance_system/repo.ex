defmodule AttendanceSystem.Repo do
  use Ecto.Repo,
    otp_app: :attendance_system,
    adapter: Ecto.Adapters.Postgres
end
