defmodule Surreal.Migrations.Mig001 do
  @moduledoc """
  Initial migration with basic schema definions
  - ecuswblock table
  -
  """
  use Surreal.Migration, "20231205211701"

  defp down do
    Repo.query("remove table ecuswblock")
    Repo.query("remove table ecusprint")
    Repo.query("remove table ecusprintupload")
  end

  defp up do
    setup_swblock()
    setup_sprint()
    setup_sprint_upload()
  end

  def setup_swblock() do
    sql_setup = ~s|
    DEFINE TABLE ecuswblock SCHEMAFULL;

    -- ecuswblock fields
    DEFINE FIELD ecu_name ON TABLE ecuswblock TYPE string;
    DEFINE FIELD sw_part_nr ON TABLE ecuswblock TYPE string;
    DEFINE FIELD ywp_version ON TABLE ecuswblock TYPE string;
    DEFINE FIELD diag_id ON TABLE ecuswblock TYPE string;
    DEFINE FIELD brop_level ON TABLE ecuswblock TYPE string;
    DEFINE FIELD sw_type ON TABLE ecuswblock TYPE string
      ASSERT $value INSIDE ["appsw", "bootloader", "other"];

    -- ecuswblock indexes
    DEFINE INDEX ecu_name ON TABLE ecuswblock COLUMNS ecu_name;
    DEFINE INDEX sw_part_nr ON TABLE ecuswblock COLUMNS sw_part_nr;
    DEFINE INDEX ywp_version ON TABLE ecuswblock COLUMNS ywp_version;
    DEFINE INDEX diag_id ON TABLE ecuswblock COLUMNS diag_id;
    DEFINE INDEX sw_type ON TABLE ecuswblock COLUMNS sw_type;

    DEFINE INDEX unique_combo ON TABLE ecuswblock COLUMNS
      ecu_name, sw_part_nr, ywp_version, diag_id, brop_level UNIQUE;
    |

    {:ok, _} = Repo.query(sql_setup)
  end

  def setup_sprint() do
    sql_setup = ~s|
    DEFINE TABLE ecusprint SCHEMAFULL;

    -- ecusprint fields
    DEFINE FIELD name ON TABLE ecusprint TYPE string
      VALUE string::lowercase($value);
    DEFINE FIELD updated ON TABLE ecusprint TYPE datetime
      DEFAULT time::now();

    -- ecusprint indexes
    DEFINE INDEX name ON TABLE ecusprint COLUMNS name UNIQUE;
    |

    {:ok, _} = Repo.query(sql_setup)
  end

  def setup_sprint_upload() do
    sql_setup = ~s|
    DEFINE TABLE ecusprintupload SCHEMAFULL;

    -- ecusprintupload fields
    DEFINE FIELD name ON TABLE ecusprintupload TYPE string
      VALUE string::lowercase($value);
    DEFINE FIELD updated ON TABLE ecusprintupload TYPE datetime
      DEFAULT time::now();

    -- ecusprintupload indexes
    DEFINE INDEX name ON TABLE ecusprintupload COLUMNS name UNIQUE;
    |

    {:ok, _} = Repo.query(sql_setup)
  end
end
