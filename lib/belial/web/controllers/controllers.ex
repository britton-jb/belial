defmodule Belial.Web.Controllers do
  def keys_to_atoms(string_key_map) when is_map(string_key_map) do
    for {key, val} <- string_key_map,
        into: %{},
        do: {String.to_existing_atom(key), keys_to_atoms(val)}
  end

  def keys_to_atoms(string_key_list) when is_list(string_key_list) do
    Enum.map(string_key_list, &keys_to_atoms/1)
  end

  def keys_to_atoms(value), do: value

  def keys_to_strings(string_key_map) when is_map(string_key_map) do
    for {key, val} <- string_key_map,
        into: %{},
        do: keys_to_strings(key, val)
  end

  def keys_to_strings(string_key_list) when is_list(string_key_list) do
    Enum.map(string_key_list, &keys_to_strings/1)
  end

  def keys_to_strings(value), do: value

  def keys_to_strings(key, val) when is_atom(key) do
    {Atom.to_string(key), keys_to_strings(val)}
  end

  def keys_to_strings(key, val) do
    {key, keys_to_strings(val)}
  end
end
