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

      def save!(o) do
        Riak.put o
      end

      def delete!(o) do
        Riak.delete o.bucket, o.key
      end

      def to_robj(o) do
        unless o.key do o = o.key(:undefined) end

        {:ok, json} = JSON.encode(o.__obj__(:obj_kw, o))

        robj = :riakc_obj.new(
          o.bucket,
          o.key, 
          json,
          o.content_type)

        if o.vclock do robj = :riakc_obj.set_vclock(robj, o.vclock) end
        if o.metadata do robj = :riakc_obj.update_metadata(robj, o.metadata) end

        robj
      end

      @before_compile Elixiak.Obj
      @elixiak_fields []
      @record_fields []

      @elixiak_model opts[:model]
      field(:model, :virtual, default: opts[:model])
      field(:key, :virtual, default: nil)
      field(:bucket, :virtual, default: nil)
      field(:metadata, :virtual, default: nil)
      field(:vclock, :virtual, default: nil)
      field(:content_type, :virtual, default: "application/json")
      field(:indexes, :virtual, default: [])
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    mod = env.module

    all_fields  = Module.get_attribute(mod, :elixiak_fields) |> Enum.reverse
    record_fields = Module.get_attribute(mod, :record_fields)
    Record.deffunctions(record_fields, env)

    fields = Enum.filter(all_fields, fn({ _, opts }) -> 
      opts[:type] != :virtual 
    end)

    [ elixiak_fields(fields),
      elixiak_helpers(fields, all_fields)]
  end

  def __field__(mod, name, type, opts) do
    check_type!(type)
    fields = Module.get_attribute(mod, :elixiak_fields)

    clash = Enum.any?(fields, fn({ prev, _ }) -> name == prev end)
    if clash do
      raise ArgumentError, message: "field `#{name}` was already set on obj"
    end

    record_fields = Module.get_attribute(mod, :record_fields)

    Module.put_attribute(mod, :record_fields, record_fields ++ [{ name, opts[:default] }])
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

    indexes = Enum.filter_map(fields, 
      fn({ _name, opts }) -> opts[:indexed] == true end, 
      fn({ name, opts }) -> 
        if opts[:type] == :integer do
          {name, {:integer_index, "#{name}"}}
        else
          {name, {:binary_index, "#{name}"}}
        end
      end)

    quoted ++ [ quote do
      def __obj__(:field, _), do: nil
      def __obj__(:field_type, _), do: nil
      def __obj__(:field_names), do: unquote(field_names)
      def __obj__(:indexes), do: unquote(indexes)
    end ]
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
        [_module|values] = tuple_to_list(obj)
        zipped = Enum.zip(unquote(all_field_names), values)

        Enum.filter(zipped, fn { field, _ } ->
          __obj__(:field, field)
        end)
      end
    end
  end
end