defmodule Ton.Wallet do
  @moduledoc """
  Defines a wallet
  """

  alias Ton.Bitstring
  alias Ton.Boc
  alias Ton.Cell

  defstruct [:initial_code, :initial_data, :workchain, :wallet_id, :public_key]

  @type t :: %__MODULE__{
          initial_code: Cell.t(),
          initial_data: Cell.t(),
          workchain: integer(),
          wallet_id: integer(),
          public_key: binary()
        }

  @wallet_v4_source Base.decode64!(
                      "te6ccgECFAEAAtQAART/APSkE/S88sgLAQIBIAIDAgFIBAUE+PKDCNcYINMf0x/THwL4I7vyZO1E0NMf0x/T//QE0VFDuvKhUVG68qIF+QFUEGT5EPKj+AAkpMjLH1JAyx9SMMv/UhD0AMntVPgPAdMHIcAAn2xRkyDXSpbTB9QC+wDoMOAhwAHjACHAAuMAAcADkTDjDQOkyMsfEssfy/8QERITAubQAdDTAyFxsJJfBOAi10nBIJJfBOAC0x8hghBwbHVnvSKCEGRzdHK9sJJfBeAD+kAwIPpEAcjKB8v/ydDtRNCBAUDXIfQEMFyBAQj0Cm+hMbOSXwfgBdM/yCWCEHBsdWe6kjgw4w0DghBkc3RyupJfBuMNBgcCASAICQB4AfoA9AQw+CdvIjBQCqEhvvLgUIIQcGx1Z4MesXCAGFAEywUmzxZY+gIZ9ADLaRfLH1Jgyz8gyYBA+wAGAIpQBIEBCPRZMO1E0IEBQNcgyAHPFvQAye1UAXKwjiOCEGRzdHKDHrFwgBhQBcsFUAPPFiP6AhPLassfyz/JgED7AJJfA+ICASAKCwBZvSQrb2omhAgKBrkPoCGEcNQICEekk30pkQzmkD6f+YN4EoAbeBAUiYcVnzGEAgFYDA0AEbjJftRNDXCx+AA9sp37UTQgQFA1yH0BDACyMoHy//J0AGBAQj0Cm+hMYAIBIA4PABmtznaiaEAga5Drhf/AABmvHfaiaEAQa5DrhY/AAG7SB/oA1NQi+QAFyMoHFcv/ydB3dIAYyMsFywIizxZQBfoCFMtrEszMyXP7AMhAFIEBCPRR8qcCAHCBAQjXGPoA0z/IVCBHgQEI9FHyp4IQbm90ZXB0gBjIywXLAlAGzxZQBPoCFMtqEssfyz/Jc/sAAgBsgQEI1xj6ANM/MFIkgQEI9Fnyp4IQZHN0cnB0gBjIywXLAlAFzxZQA/oCE8tqyx8Syz/Jc/sAAAr0AMntVA=="
                    )

  @spec create(binary(), integer(), integer()) :: t()
  def create(public_key, workchain \\ 0, wallet_id \\ 698_983_191) do
    source_code = @wallet_v4_source |> Boc.parse() |> Enum.at(0)
    initial_data = Cell.new()

    data =
      initial_data.data
      |> Bitstring.write_uint(0, 32)
      |> Bitstring.write_uint(wallet_id, 32)
      |> Bitstring.write_binary(public_key)
      |> Bitstring.write_bit(0)

    initial_data = %{initial_data | data: data}

    %__MODULE__{
      initial_code: source_code,
      initial_data: initial_data,
      workchain: workchain,
      wallet_id: wallet_id,
      public_key: public_key
    }
  end

  @spec state_init_cell(t(), Cell.t() | nil) :: Cell.t()
  def state_init_cell(wallet, cell \\ nil) do
    cell = cell || Cell.new()

    data =
      cell.data
      # SplitDepth
      |> Bitstring.write_bit(0)
      # TickTock
      |> Bitstring.write_bit(0)
      # Code present
      |> Bitstring.write_bit(1)
      # data presense
      |> Bitstring.write_bit(1)
      # library
      |> Bitstring.write_bit(0)

    %{cell | refs: cell.refs ++ [wallet.initial_code, wallet.initial_data], data: data}
  end

  @spec hash(t()) :: binary()
  def hash(wallet) do
    wallet
    |> state_init_cell()
    |> Cell.hash()
  end
end
