defmodule Surreal.Converter do
  def convert!(struct_module, value) do
    cond do
      has_function(struct_module, :__table__, 0) -> convert_constructor(struct_module, value)
      has_function(struct_module, :__schema__, 1) -> convert_ecto(struct_module, value)
      true -> raise "NOT POSSIBLE TO MAP #{struct_module}"
    end
  end

  defp convert_constructor(struct_module, value) do
    struct_module.make!(value)
  end

  defp convert_ecto(struct_module, value) do
    attr_list = ecto_fields(struct_module)

    Ecto.Changeset.cast(struct(struct_module), value, attr_list)
    |> Map.put(:action, :insert)
    |> Ecto.Changeset.apply_action(:insert)
    |> Maxo.Result.unwrap!()
  end

  defp ecto_fields(module) do
    module.__schema__(:dump) |> Map.keys()
  end

  defp has_function(mod, fun, arity) do
    Kernel.function_exported?(mod, fun, arity)
  end
end
