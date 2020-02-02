defmodule Belial.CompileTimeError do
  defexception [:message]

  @impl true
  def exception(message), do: %__MODULE__{message: message}

  def test_module_attributes_defined?(schema) do
    unless function_exported?(schema, :__test_factory, 0) do
      raise(
        Belial.CompileTimeError,
        "#{schema} - a Belial.Schema must define `__test_factory/0` returning an ExMachina Factory module"
      )
    end

    unless function_exported?(schema, :__test_resource_atom, 0) do
      raise(
        Belial.CompileTimeError,
        "#{schema} - a Belial.Schema must define `__test_resource_atom/0` returning an atom defining it's ExMachina factory"
      )
    end

    unless function_exported?(schema, :__test_repo, 0) do
      raise(
        Belial.CompileTimeError,
        "#{schema} must define `__test_repo/0`, returning an Ecto.Repo"
      )
    end
  end
end
