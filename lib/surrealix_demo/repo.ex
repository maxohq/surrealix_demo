defmodule SurrealixDemo.Repo do
  use Ecto.Repo,
    otp_app: :surrealix_demo,
    adapter: Ecto.Adapters.Postgres
end
