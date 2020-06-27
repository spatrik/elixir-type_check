defmodule TypeCheck.Builtin.Tuple do
  defstruct [:element_types]

  defimpl TypeCheck.Protocols.ToCheck do
    def to_check(%{element_types: types_list}, param) do
      element_checks_ast = build_element_checks_ast(types_list, param)
      expected_size = length(types_list)
      quote do
        case unquote(param) do
          x when not is_tuple(x) ->
            {:error, {TypeCheck.Builtin.Tuple, :not_a_tuple, %{}, x}}
          x when tuple_size(x) != unquote(expected_size) ->
            {:error, {TypeCheck.Builtin.Tuple, :different_size, %{}, x}}
          _ ->
            unquote(element_checks_ast)
        end
      end
    end

    defp build_element_checks_ast(types_list, param) do
      element_checks =
        types_list
        |> Enum.with_index
        |> Enum.map(fn {element_type, index} ->
        impl = TypeCheck.Protocols.ToCheck.to_check(element_type, quote do elem(unquote(param), unquote(index)) end)
        quote do
          {:ok, _index, _element_type} <- {unquote(impl), unquote(index), unquote(Macro.escape(element_type))}
        end
      end)

        quote do
          with unquote_splicing(element_checks) do
            :ok
          else
            {error, index, element_type} ->
              {:error, {TypeCheck.Builtin.Tuple, :element_error, %{problem: error, index: index, element_type: Macro.escape(element_type)}, unquote(param)}}
          end
        end
    end
  end

  defimpl TypeCheck.Protocols.Inspect do
    def inspect(tuple, opts) do
      Inspect.Algebra.container_doc("{", tuple.element_types, "}", opts, &TypeCheck.Protocols.Inspect.inspect/2, [separator: ", ", break: :maybe])
    end
  end
end