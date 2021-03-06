Code.require_file "test_helper.exs", __DIR__

defmodule KernelTest do
  use ExUnit.Case, async: true

  doctest Kernel

  test "=~/2" do
    assert ("abcd" =~ ~r/c(d)/) == true
    assert ("abcd" =~ ~r/e/) == false
    assert ("abcd" =~ ~R/c(d)/) == true
    assert ("abcd" =~ ~R/e/) == false

    string = "^ab+cd*$"
    assert (string =~ "ab+") == true
    assert (string =~ "bb") == false

    assert ("abcd" =~ ~r//) == true
    assert ("abcd" =~ ~R//) == true
    assert ("abcd" =~ "") == true

    assert ("" =~ ~r//) == true
    assert ("" =~ ~R//) == true
    assert ("" =~ "") == true

    assert ("" =~ "abcd") == false
    assert ("" =~ ~r/abcd/) == false
    assert ("" =~ ~R/abcd/) == false

    assert_raise FunctionClauseError, "no function clause matching in Kernel.=~/2", fn ->
      1234 =~ "hello"
    end

    assert_raise FunctionClauseError, "no function clause matching in Kernel.=~/2", fn ->
      1234 =~ ~r"hello"
    end

    assert_raise FunctionClauseError, "no function clause matching in Kernel.=~/2", fn ->
      1234 =~ ~R"hello"
    end

    assert_raise FunctionClauseError, "no function clause matching in Kernel.=~/2", fn ->
      ~r"hello" =~ "hello"
    end

    assert_raise FunctionClauseError, "no function clause matching in Kernel.=~/2", fn ->
      ~r"hello" =~ ~r"hello"
    end

    assert_raise FunctionClauseError, "no function clause matching in Kernel.=~/2", fn ->
      :abcd =~ ~r//
    end

    assert_raise FunctionClauseError, "no function clause matching in Kernel.=~/2", fn ->
      :abcd =~ ""
    end

    assert_raise FunctionClauseError, "no function clause matching in Regex.match?/2", fn ->
      "abcd" =~ nil
    end

    assert_raise FunctionClauseError, "no function clause matching in Regex.match?/2", fn ->
      "abcd" =~ :abcd
    end
  end

  test "^" do
    x = List.first([1])

    assert_raise MatchError, fn ->
      {x, ^x} = {2, 2}
      x
    end
  end

  test "match?/2" do
    assert match?(_, List.first(1)) == true
    assert binding() == []

    a = List.first([0])
    assert match?(b when b > a, 1) == true
    assert binding() == [a: 0]

    assert match?(b when b > a, -1) == false
    assert binding() == [a: 0]
  end

  test "in/2" do
    assert 2 in [1, 2, 3]
    assert 2 in 1..3
    refute 4 in [1, 2, 3]
    refute 4 in 1..3

    list = [1, 2, 3]
    assert 2 in list
    refute 4 in list
  end

  @at_list  [4, 5]
  @at_range 6..8
  def fun_in(x) when x in [0],       do: :list
  def fun_in(x) when x in 1..3,      do: :range
  def fun_in(x) when x in @at_list,  do: :at_list
  def fun_in(x) when x in @at_range, do: :at_range
  def fun_in(_), do: :none

  test "in/2 in function guard" do
    assert fun_in(0) == :list
    assert fun_in(1) == :range
    assert fun_in(2) == :range
    assert fun_in(3) == :range
    assert fun_in(5) == :at_list
    assert fun_in(6) == :at_range
    assert fun_in(7) == :at_range
    assert fun_in(8) == :at_range

    assert fun_in(0.0) == :none
    assert fun_in(1.0) == :none
    assert fun_in(2.0) == :none
    assert fun_in(3.0) == :none
    assert fun_in(6.0) == :none
    assert fun_in(7.0) == :none
    assert fun_in(8.0) == :none
  end

  def fun_in(x, y, z) when x in y..z, do: true
  def fun_in(_x, _y, _z), do: false

  test "in/2 in dynamic function guard" do
    assert fun_in(1, 1, 3)
    assert fun_in(2, 1, 3)
    assert fun_in(3, 1, 3)

    assert fun_in(1, 3, 1)
    assert fun_in(2, 3, 1)
    assert fun_in(3, 3, 1)

    refute fun_in(0, 1, 3)
    refute fun_in(4, 1, 3)
    refute fun_in(0, 3, 1)
    refute fun_in(4, 3, 1)

    refute fun_in(2, 1.0, 3)
    refute fun_in(2, 1, 3.0)
    refute fun_in(2.0, 1, 3)
  end

  defmacrop case_in(x, y) do
    quote do
      case 0 do
        _ when unquote(x) in unquote(y) -> true
        _ -> false
      end
    end
  end

  test "in/2 in case guard" do
    assert case_in(1, [1, 2, 3]) == true
    assert case_in(1, 1..3) == true
    assert case_in(2, 1..3) == true
    assert case_in(3, 1..3) == true
    assert case_in(-3, -1..-3) == true
  end

  test "in/2 in module body" do
    defmodule In do
      @foo [:a, :b]
      true = :a in @foo
    end
  end

  @bitstring <<"foo", 16::4>>

  test "bitstring attribute" do
    assert @bitstring == <<"foo", 16::4>>
  end

  test "paren as nil" do
    assert is_nil(()) == true
    assert (_ = (); ();) == nil
    assert [ 1, (), 3 ] == [1, nil, 3 ]
    assert [do: ()] == [do: nil]
    assert {1, (), 3} == {1, nil, 3}
    assert (Kernel.&& nil, ()) == nil
    assert (Kernel.&& nil, ()) == nil
    assert (() && ()) == nil
    assert (if(() && ()) do
      :ok
    else
      :error
    end) == :error
  end

  test "__info__(:macros)" do
    assert {:in, 2} in Kernel.__info__(:macros)
  end

  test "__info__(:functions)" do
    refute {:__info__, 1} in Kernel.__info__(:functions)
  end

  test "__info__(others)" do
    assert Kernel.__info__(:module) == Kernel
    assert is_list Kernel.__info__(:compile)
    assert is_list Kernel.__info__(:attributes)
    assert is_list Kernel.__info__(:exports)
  end

  def exported?,      do: not_exported?
  defp not_exported?, do: true

  test "function_exported?/3" do
    assert function_exported?(__MODULE__, :exported?, 0)
    refute function_exported?(__MODULE__, :not_exported?, 0)
  end

  test "macro_exported?/3" do
    assert macro_exported?(Kernel, :in, 2) == true
    assert macro_exported?(Kernel, :def, 1) == true
    assert macro_exported?(Kernel, :def, 2) == true
    assert macro_exported?(Kernel, :def, 3) == false
    assert macro_exported?(Kernel, :no_such_macro, 2) == false
  end

  test "apply/3 and apply/2" do
    assert apply(Enum, :reverse, [[1|[2, 3]]]) == [3, 2, 1]
    assert apply(fn x -> x * 2 end, [2]) == 4
  end

  test "binding/0 and binding/1" do
    x = 1
    assert binding() == [x: 1]

    x = 2
    assert binding() == [x: 2]

    y = 3
    assert binding() == [x: 2, y: 3]

    var!(x, :foo) = 4
    assert binding() == [x: 2, y: 3]
    assert binding(:foo) == [x: 4]
  end

  test "binding/0 doesn't warn on underscored vars" do
    _x = 1
    assert binding() == [_x: 1]
  end

  defmodule User do
    assert is_map defstruct name: "john"
  end

  defmodule UserTuple do
    def __struct__({ UserTuple, :ok }) do
      %User{}
    end
  end

  test "struct/1 and struct/2" do
    assert struct(User) == %User{name: "john"}

    user = struct(User, name: "meg")
    assert user == %User{name: "meg"}

    assert struct(user, unknown: "key") == user
    assert struct(user, %{name: "john"}) == %User{name: "john"}
    assert struct(user, name: "other", __struct__: Post) == %User{name: "other"}
  end

  test "struct!/1 and struct!/2" do
    assert struct!(User) == %User{name: "john"}

    user = struct!(User, name: "meg")
    assert user == %User{name: "meg"}

    assert_raise KeyError, fn ->
      struct!(user, unknown: "key")
    end

    assert struct!(user, %{name: "john"}) == %User{name: "john"}
    assert struct!(user, name: "other", __struct__: Post) == %User{name: "other"}
  end

  defdelegate my_flatten(list), to: List, as: :flatten
  defdelegate [map(callback, list)], to: :lists, append_first: true

  dynamic = :dynamic_flatten
  defdelegate unquote(dynamic)(list), to: List, as: :flatten

  test "defdelegate/2" do
    assert my_flatten([[1]]) == [1]
  end

  test "defdelegate/2 with :append_first" do
    assert map([1], fn(x) -> x + 1 end) == [2]
  end

  test "defdelegate/2 with unquote" do
    assert dynamic_flatten([[1]]) == [1]
  end

  test "defdelegate/2 raises with non-variable arguments" do
    code = quote do
      defmodule Foo do
        defdelegate foo(1), to: List
      end
    end

    msg = "defdelegate/2 only accepts variable names, got: 1"
    assert_raise ArgumentError, msg, fn -> Code.compile_quoted(code) end

    code = quote do
      defmodule Foo do
        defdelegate foo(a \\ 1), to: List
      end
    end

    msg = "defdelegate/2 only accepts variable names, got: a \\\\ 1"
    assert_raise ArgumentError, msg, fn -> Code.compile_quoted(code) end
  end

  test "get_in/2" do
    users = %{"john" => %{age: 27}, "meg" => %{age: 23}}
    assert get_in(users, ["john", :age]) == 27
    assert get_in(users, ["dave", :age]) == nil
    assert get_in(nil, ["john", :age]) == nil

    map = %{"fruits" => ["banana", "apple", "orange"]}
    assert get_in(map, ["fruits", by_index(0)])  == "banana"
    assert get_in(map, ["fruits", by_index(3)])  == nil
    assert get_in(map, ["unknown", by_index(3)]) == :oops

    assert_raise FunctionClauseError, fn ->
      get_in(users, [])
    end
  end

  test "put_in/3" do
    users = %{"john" => %{age: 27}, "meg" => %{age: 23}}

    assert put_in(users, ["john", :age], 28) ==
           %{"john" => %{age: 28}, "meg" => %{age: 23}}

    assert_raise FunctionClauseError, fn ->
      put_in(users, [], %{})
    end

    assert_raise ArgumentError, "could not put/update key \"john\" on a nil value", fn ->
      put_in(nil, ["john", :age], 28)
    end
  end

  test "put_in/2" do
    users = %{"john" => %{age: 27}, "meg" => %{age: 23}}

    assert put_in(users["john"][:age], 28) ==
           %{"john" => %{age: 28}, "meg" => %{age: 23}}

    assert put_in(users["john"].age, 28) ==
           %{"john" => %{age: 28}, "meg" => %{age: 23}}

    assert_raise BadMapError, fn ->
      put_in(users["dave"].age, 19)
    end

    assert_raise KeyError, fn ->
      put_in(users["meg"].unknown, "value")
    end
  end

  test "update_in/3" do
    users = %{"john" => %{age: 27}, "meg" => %{age: 23}}

    assert update_in(users, ["john", :age], &(&1 + 1)) ==
           %{"john" => %{age: 28}, "meg" => %{age: 23}}

    assert_raise FunctionClauseError, fn ->
      update_in(users, [], fn _ -> %{} end)
    end

    assert_raise ArgumentError, "could not put/update key \"john\" on a nil value", fn ->
      update_in(nil, ["john", :age], fn _ -> %{} end)
    end
  end

  test "update_in/2" do
    users = %{"john" => %{age: 27}, "meg" => %{age: 23}}

    assert update_in(users["john"][:age], &(&1 + 1)) ==
           %{"john" => %{age: 28}, "meg" => %{age: 23}}

    assert update_in(users["john"].age, &(&1 + 1)) ==
           %{"john" => %{age: 28}, "meg" => %{age: 23}}

    assert_raise BadMapError, fn ->
      update_in(users["dave"].age, &(&1 + 1))
    end

    assert_raise KeyError, fn ->
      put_in(users["meg"].unknown, &(&1 + 1))
    end
  end

  test "get_and_update_in/3" do
    users = %{"john" => %{age: 27}, "meg" => %{age: 23}}

    assert get_and_update_in(users, ["john", :age], &{&1, &1 + 1}) ==
           {27, %{"john" => %{age: 28}, "meg" => %{age: 23}}}

    map = %{"fruits" => ["banana", "apple", "orange"]}
    assert get_and_update_in(map, ["fruits", by_index(0)], &{&1, String.reverse(&1)}) ==
           {"banana", %{"fruits" => ["ananab", "apple", "orange"]}}

    assert get_and_update_in(map, ["fruits", by_index(3)], &{&1, &1}) ==
           {nil, %{"fruits" => ["banana", "apple", "orange"]}}

    assert get_and_update_in(map, ["unknown", by_index(3)], &{&1, []}) ==
           {:oops, %{"fruits" => ["banana", "apple", "orange"], "unknown" => []}}

    assert_raise FunctionClauseError, fn ->
      update_in(users, [], fn _ -> %{} end)
    end
  end

  test "get_and_update_in/2" do
    users = %{"john" => %{age: 27}, "meg" => %{age: 23}}

    assert get_and_update_in(users["john"].age, &{&1, &1 + 1}) ==
           {27, %{"john" => %{age: 28}, "meg" => %{age: 23}}}

    assert_raise ArgumentError, "could not put/update key \"john\" on a nil value", fn ->
      get_and_update_in(nil["john"][:age], fn nil -> {:ok, 28} end)
    end

    assert_raise BadMapError, fn ->
      get_and_update_in(users["dave"].age, &{&1, &1 + 1})
    end

    assert_raise KeyError, fn ->
      get_and_update_in(users["meg"].unknown, &{&1, &1 + 1})
    end
  end

  test "paths" do
    map = empty_map()

    assert put_in(map[:foo], "bar") == %{foo: "bar"}
    assert put_in(empty_map()[:foo], "bar") == %{foo: "bar"}
    assert put_in(KernelTest.empty_map()[:foo], "bar") == %{foo: "bar"}
    assert put_in(__MODULE__.empty_map()[:foo], "bar") == %{foo: "bar"}

    assert_raise ArgumentError, ~r"access at least one element,", fn ->
      Code.eval_quoted(quote(do: put_in(map, "bar")), [])
    end

    assert_raise ArgumentError, ~r"must start with a variable, local or remote call", fn ->
      Code.eval_quoted(quote(do: put_in(map.foo(1, 2)[:bar], "baz")), [])
    end
  end

  def empty_map, do: %{}

  def by_index(index) do
    fn
      _, nil, next ->
        next.(:oops)
      :get, data, next ->
        next.(Enum.at(data, index))
      :get_and_update, data, next ->
        {get, update} = next.(Enum.at(data, index))
        {get, List.replace_at(data, index, update)}
    end
  end

  defmodule PipelineOp do
    use ExUnit.Case, async: true

    test "simple" do
      assert [1, [2], 3] |> List.flatten == [1, 2, 3]
    end

    test "nested pipelines" do
      assert [1, [2], 3] |> List.flatten |> Enum.map(&(&1 * 2)) == [2, 4, 6]
    end

    test "local call" do
      assert [1, [2], 3] |> List.flatten |> local == [2, 4, 6]
    end

    test "pipeline with capture" do
      assert Enum.map([1, 2, 3], &(&1 |> twice |> twice)) == [4, 8, 12]
    end

    test "anonymous functions" do
      assert  1  |> (&(&1*2)).() == 2
      assert [1] |> (&hd(&1)).() == 1
    end

    defp twice(a), do: a * 2

    defp local(list) do
      Enum.map(list, &(&1 * 2))
    end
  end

  defmodule IfScope do
    use ExUnit.Case, async: true

    test "variables on nested if" do
      {a, b} = {nil, nil}

      if true do
        a = 1
        if true do
          b = 2
        end
      end

      assert a == 1
      assert b == 2
    end

    test "variables on sibling if" do
      {a, b, c} = {nil, nil, nil}

      if true do
        a = 1

        if true do
          b = 2
        end

        if true do
          c = 3
        end
      end

      assert a == 1
      assert b == 2
      assert c == 3
    end

    test "variables counter on nested ifs" do
      r = (fn() -> 3 end).() # supresses warning at (if r < 0...)
      r = r - 1
      r = r - 1
      r = r - 1

      if true do
        r = r - 1
        if r < 0, do: r = 0
      end

      assert r == 0
    end

    test "calling if with invalid keys" do
      error_message = "invalid or duplicate keys for if, only \"do\" " <>
      "and an optional \"else\" are permitted"
      assert_raise ArgumentError, error_message, fn ->
        Code.eval_string("if true, foo: 7")
      end

      assert_raise ArgumentError, error_message, fn ->
        Code.eval_string("if true, do: 6, boo: 7")
      end

      assert_raise ArgumentError, error_message, fn ->
        Code.eval_string("if true, do: 7, do: 6")
      end

      assert_raise ArgumentError, error_message, fn ->
        Code.eval_string("if true, do: 8, else: 7, else: 6")
      end

      assert_raise ArgumentError, error_message, fn ->
        Code.eval_string("if true, else: 6")
      end

      assert_raise ArgumentError, error_message, fn ->
        Code.eval_string("if true, []")
      end
    end

    test "calling unless with invalid keys" do
      error_message = "invalid or duplicate keys for unless, only \"do\" " <>
        "and an optional \"else\" are permitted"
      assert_raise ArgumentError, error_message, fn ->
        Code.eval_string("unless true, foo: 7")
      end

      assert_raise ArgumentError, error_message, fn ->
        Code.eval_string("unless true, do: 6, boo: 7")
      end

      assert_raise ArgumentError, error_message, fn ->
        Code.eval_string("unless true, do: 7, do: 6")
      end

      assert_raise ArgumentError, error_message, fn ->
        Code.eval_string("unless true, do: 8, else: 7, else: 6")
      end

      assert_raise ArgumentError, error_message, fn ->
        Code.eval_string("unless true, else: 6")
      end

      assert_raise ArgumentError, error_message, fn ->
        Code.eval_string("unless true, []")
      end
    end
  end

  defmodule Destructure do
    use ExUnit.Case, async: true

    test "less args" do
      destructure [x, y, z], [1, 2, 3, 4, 5]
      assert x == 1
      assert y == 2
      assert z == 3
    end

    test "more args" do
      destructure [a, b, c, d, e], [1, 2, 3]
      assert a == 1
      assert b == 2
      assert c == 3
      assert d == nil
      assert e == nil
    end

    test "equal args" do
      destructure [a, b, c], [1, 2, 3]
      assert a == 1
      assert b == 2
      assert c == 3
    end

    test "no values" do
      destructure [a, b, c], []
      assert a == nil
      assert b == nil
      assert c == nil
    end

    test "works as match" do
      destructure [1, b, _], [1, 2, 3]
      assert b == 2
    end

    test "nil values" do
      destructure [a, b, c], a_nil
      assert a == nil
      assert b == nil
      assert c == nil
    end

    test "invalid match" do
      a = List.first([3])
      assert_raise MatchError, fn ->
        destructure [^a, _b, _c], a_list
      end
    end

    defp a_list, do: [1, 2, 3]
    defp a_nil, do: nil
  end

  defmodule UseMacro do
    use ExUnit.Case, async: true

    import ExUnit.CaptureIO

    defmodule SampleA do
      defmacro __using__(opts) do
        prefix = Keyword.get(opts, :prefix, "")
        IO.puts(prefix <> "A")
      end
    end

    defmodule SampleB do
      defmacro __using__(_) do
        IO.puts("B")
      end
    end

    test "invalid argument is literal" do
      message = "invalid arguments for use, expected a compile time atom or alias, got: 42"
      assert_raise ArgumentError, message, fn ->
        Code.eval_string("use 42")
      end
    end

    test "invalid argument is variable" do
      message = "invalid arguments for use, expected a compile time atom or alias, got: variable"
      assert_raise ArgumentError, message, fn ->
        Code.eval_string("use variable")
      end
    end

    test "multi-call" do
      assert capture_io(fn ->
        Code.eval_string("use UseMacro.{SampleA, SampleB,}", [], __ENV__)
      end) == "A\nB\n"
    end

    test "multi-call with options" do
      assert capture_io(fn ->
        Code.eval_string(~S|use UseMacro.{SampleA}, prefix: "-"|, [], __ENV__)
      end) == "-A\n"
    end

    test "multi-call with unquote" do
      assert capture_io(fn ->
        Code.eval_string("""
          defmodule TestMod do
            def main() do
              use UseMacro.{SampleB, unquote(:SampleA)}
            end
          end
          """, [], __ENV__)
      end) == "B\nA\n"
    after
      :code.purge(UseMacro.TestMod)
      :code.delete(UseMacro.TestMod)
    end
  end
end
