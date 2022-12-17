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
        assert value |> Utils.sha256() |> Base.encode16(case: :lower) == output
      end
    end
  end

  describe "sign/2" do
    test "signs data with a private key" do
      private_key =
        <<216, 145, 38, 65, 213, 88, 1, 110, 133, 87, 170, 172, 147, 33, 96, 73, 164, 121, 52, 37,
          94, 100, 25, 147, 124, 8, 232, 161, 104, 122, 232, 44, 218, 140, 98, 244, 76, 48, 223,
          187, 117, 177, 228, 75, 120, 10, 202, 138, 48, 149, 51, 209, 225, 87, 148, 132, 229,
          110, 178, 4, 19, 205, 1, 218>>

      assert {:ok,
              <<224, 113, 68, 135, 55, 227, 57, 151, 72, 18, 36, 150, 19, 17, 39, 105, 225, 90,
                59, 81, 148, 190, 248, 80, 140, 96, 184, 235, 231, 20, 217, 136, 237, 248, 86, 3,
                156, 19, 255, 145, 224, 170, 192, 34, 224, 73, 158, 196, 38, 182, 100, 93, 88,
                229, 119, 172, 64, 190, 251, 240, 121, 53, 194, 14,
                49>>} = Utils.sign("1", private_key)
    end
  end
end
