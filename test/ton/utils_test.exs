defmodule Ton.UtilsTest do
  use ExUnit.Case

  alias Ton.Utils

  describe "sha256/1" do
    test "calculates hash" do
      tests = [
        %{
          value: "abc",
          output: "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        },
        %{value: "", output: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"},
        %{
          value: "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
          output: "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1"
        }
      ]

      for %{value: value, output: output} <- tests do
        assert Utils.sha256(value) == output
      end
    end
  end
end
