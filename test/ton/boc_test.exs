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

      assert %Ton.Boc{
               header: %Ton.Boc.Header{
                 has_idx: false,
                 hash_crc32: true,
                 has_cache_bits: false,
                 flags: 0,
                 size_bytes: 1,
                 off_bytes: 1,
                 cells_num: 1,
                 roots_num: 1,
                 absent_num: 0,
                 tot_cells_size: 68,
                 root_list: [0],
                 index: [],
                 cells_data: _
               },
               cells: [
                 %Ton.Cell{
                   refs: [],
                   data: %Ton.Bitstring{
                     length: 528,
                     array: _,
                     cursor: 528
                   },
                   kind: :ordinary
                 }
               ]
             } = Boc.parse(contract_source_code)
    end
  end
end
