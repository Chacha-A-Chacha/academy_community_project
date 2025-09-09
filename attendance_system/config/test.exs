import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :attendance_system, AttendanceSystem.Repo,
  username: env!("DB_USERNAME", :string, "postgres"),
  password: env!("DB_PASSWORD", :string, "postgres"),
  hostname: env!("DB_HOSTNAME", :string, "localhost"),
  database: env!("DB_NAME", :string, "attendance_system_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :attendance_system, AttendanceSystemWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "yXiGyp5rkl9IUBUYtL/aJLtZuFHdb9dqfykmub5ZtTKQdJzfwVL4yY7hzb2lZ+Gi",
  server: false

# In test we don't send emails
config :attendance_system, AttendanceSystem.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Disable Oban in test
config :attendance_system, Oban, testing: :inline

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
