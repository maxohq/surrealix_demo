defmodule Surreal.Migrations.Mig002 do
  @moduledoc """
  Seeding Ecu Unit mapping to powertrain / telemetric types
  """
  use Surreal.Migration, "20231206002610"

  defp down do
    Repo.query("remove table ecuunit")
  end

  defp up do
    setup_schema()
    insert_data()
  end

  defp setup_schema do
    sql_setup = ~s|
    DEFINE TABLE ecuunit SCHEMAFULL;

    -- ecuunit fields
    DEFINE FIELD ecu ON TABLE ecuunit TYPE string;
    DEFINE FIELD type ON TABLE ecuunit TYPE string ASSERT $value INSIDE ["telematic", "powertrain", ""];;
    DEFINE FIELD prj_key ON TABLE ecuunit TYPE string ASSERT $value INSIDE ["TDFTI", "TDFRP", ""];
    -- for some ECU units we currently do not have jiraproject id...
    DEFINE FIELD project ON TABLE ecuunit TYPE option<record<jiraproject>>;

    DEFINE INDEX ecu ON TABLE ecuunit COLUMNS ecu UNIQUE;
    |

    {:ok, _} = Repo.query(sql_setup)
  end

  defp insert_data do
    items =
      data()
      |> Enum.map(fn x ->
        Map.put(x, :id, Map.get(x, "ecu"))
      end)

    {:ok, _res} = Repo.insert("ecuunit", items)
  end

  def data do
    []
  end
end
