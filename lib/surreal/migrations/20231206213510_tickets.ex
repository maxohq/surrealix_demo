defmodule Surreal.Migrations.Mig003 do
  @moduledoc """
  Setting up Ticket schema.
  """
  use Surreal.Migration, "20231206213510"

  defp down do
    Repo.query("remove table ecusubticket")
    Repo.query("remove table ecumainticket")
  end

  defp up do
    setup_mainticket()
    setup_subticket()
  end

  defp setup_mainticket do
    sql_setup = ~s|
    DEFINE TABLE ecumainticket SCHEMAFULL;

    DEFINE FIELD ecuswblocks ON TABLE ecumainticket TYPE array<record<ecuswblock>>;
    DEFINE FIELD project ON TABLE ecumainticket TYPE record<jiraproject>;
    DEFINE FIELD summary ON TABLE ecumainticket TYPE string;
    |

    {:ok, _} = Repo.query(sql_setup)
  end

  defp setup_subticket do
    sql_setup = ~s|
    DEFINE TABLE ecusubticket SCHEMAFULL;

    -- we can have multiple
    DEFINE FIELD ecuswblocks ON TABLE ecusubticket TYPE array<record<ecuswblock>>;
    DEFINE FIELD project ON TABLE ecusubticket TYPE record<jiraproject>;
    DEFINE FIELD summary ON TABLE ecusubticket TYPE string;
    |

    {:ok, _} = Repo.query(sql_setup)
  end
end
