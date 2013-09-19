defmodule Elixiak.Obj do
  @type t :: Record.t

  defmacro field(name, type, opts // []) do
    quote do
      Elixiak.Obj.__field__(__MODULE__, unquote(name), unquote(type), unquote(opts))
    end
  end

  @types %w(boolean string integer float binary list datetime interval virtual)a

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      import Elixiak.Obj

      @before_compile Elixiak.Obj
      @elixiak_fields []
      @record_fields []
      @elixiak_primary_key nil

      @elixiak_model opts[:model]
      field(:model, :virtual, default: opts[:model])

      case opts[:primary_key] do
        nil ->
          field(:key, :string, primary_key: true)
        false ->
          :ok
        { name, type } ->
          field(name, type, primary_key: true)
        other ->
          raise ArgumentError, message: ":primary_key must be false, nil or { name, type }"
      end
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    mod = env.module

    primary_key = Module.get_attribute(mod, :elixiak_primary_key)
    all_fields  = Module.get_attribute(mod, :elixiak_fields) |> Enum.reverse

    record_fields = Module.get_attribute(mod, :record_fields)
    Record.deffunctions(record_fields, env)

    fields = Enum.filter(all_fields, fn({ _, opts }) -> opts[:type] != :virtual end)

    [ elixiak_fields(fields),
      elixiak_primary_key(primary_key),
      elixiak_helpers(fields, all_fields) ]
  end

  def __field__(mod, name, type, opts) do
    check_type!(type)
    fields = Module.get_attribute(mod, :elixiak_fields)

    if opts[:primary_key] do
      if pk = Module.get_attribute(mod, :elixiak_primary_key) do
        raise ArgumentError, message: "primary key already defined as `#{pk}`"
      else
        Module.put_attribute(mod, :elixiak_primary_key, name)
      end
    end

    clash = Enum.any?(fields, fn({ prev, _ }) -> name == prev end)
    if clash do
      raise ArgumentError, message: "field `#{name}` was already set on obj"
    end

    record_fields = Module.get_attribute(mod, :record_fields)
    Module.put_attribute(mod, :record_fields, record_fields ++ [{ name, opts[:default] }])

    opts = Enum.reduce([:default, :primary_key], opts, &Dict.delete(&2, &1))
    Module.put_attribute(mod, :elixiak_fields, [{ name, [type: type] ++ opts }|fields])
  end

  ## Helpers

  defp check_type!({ outer, inner }) when is_atom(outer) do
    check_type!(outer)
    check_type!(inner)
  end

  defp check_type!(type) do
    unless type in @types do
      raise ArgumentError, message: "`#{Macro.to_string(type)}` is not a valid field type"
    end
  end

  defp elixiak_fields(fields) do
    quoted = Enum.map(fields, fn({ name, opts }) ->
      quote do
        def __obj__(:field, unquote(name)), do: unquote(opts)
        def __obj__(:field_type, unquote(name)), do: unquote(opts[:type])
      end
    end)

    field_names = Enum.map(fields, &elem(&1, 0))
    quoted ++ [ quote do
      def __obj__(:field, _), do: nil
      def __obj__(:field_type, _), do: nil
      def __obj__(:field_names), do: unquote(field_names)
    end ]
  end

  defp elixiak_primary_key(primary_key) do
    quote do
      def __obj__(:primary_key), do: unquote(primary_key)

      if unquote(primary_key) do
        def primary_key(record), do: unquote(primary_key)(record)
        def primary_key(value, record), do: unquote(primary_key)(value, record)
        def update_primary_key(fun, record), do: unquote(:"update_#{primary_key}")(fun, record)
      else
        def primary_key(_record), do: nil
        def primary_key(_value, record), do: record
        def update_primary_key(_fun, record), do: record
      end
    end
  end

  defp elixiak_helpers(fields, all_fields) do
    field_names = Enum.map(fields, &elem(&1, 0))
    all_field_names = Enum.map(all_fields, &elem(&1, 0))

    quote do
      # TODO: This can be optimized
      def __obj__(:allocate, values) do
        zip = Enum.zip(unquote(field_names), values)
        __MODULE__.new(zip)
      end

      def __obj__(:obj_kw, obj, opts // []) do
        filter_pk = opts[:primary_key] == false
        primary_key = __obj__(:primary_key)

        [_module|values] = tuple_to_list(obj)
        zipped = Enum.zip(unquote(all_field_names), values)

        Enum.filter(zipped, fn { field, _ } ->
          __obj__(:field, field) &&
            (not filter_pk || (filter_pk && field != primary_key))
        end)
      end
    end
  end
end