defmodule Surreal.Migrations.Mig004 do
  @moduledoc """
  Some indexes for jira issue table
  """
  use Surreal.Migration, "20231208182001"

  defp down do
    Repo.query("REMOVE INDEX parent ON TABLE jiraissue")
    Repo.query("REMOVE INDEX updated ON TABLE jiraissue")
    Repo.query("REMOVE INDEX issuetype ON TABLE jiraissue")
  end

  defp up do
    setup_jira_indexes()
  end

  defp setup_jira_indexes do
    sql_setup = ~s|
    DEFINE INDEX parent ON TABLE jiraissue COLUMNS parent;
    DEFINE INDEX updated ON TABLE jiraissue COLUMNS updated;
    DEFINE INDEX issuetype ON TABLE jiraissue COLUMNS issuetype;
    |
    {:ok, _} = Repo.query(sql_setup)
  end
end
