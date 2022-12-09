defmodule Ton.BocTest do
  use ExUnit.Case

  alias Ton.Boc

  describe "parse/1" do
    test "parses header and cells" do
      {:ok, contract_source_code} =
        Base.decode16(
          "B5EE9C72410101010044000084FF0020DDA4F260810200D71820D70B1FED44D0D31FD3FFD15112BAF2A122F901541044F910F2A2F80001D31F3120D74A96D307D402FB00DED1A4C8CB1FCBFFC9ED5441FDF089",
          case: :upper
        )

      Boc.parse(contract_source_code) |> IO.inspect()
    end
  end
end
