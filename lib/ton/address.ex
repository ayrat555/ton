defmodule Ton.Address do
  import Bitwise

  alias Ton.Crc16
  alias Ton.Wallet

  @bounceable_tag 0x11
  @non_bounceable_tag 0x51
  @test_flag 0x80

  defstruct [:test_only, :bounceable, :workchain, :hash]

  def parse(address_str) do
    with {:ok, binary_address} <- decode_base64(address_str),
         :ok <- check_length(binary_address),
         {:ok, <<tag::8, workchain::8, hash::binary-size(32)>>} <- check_crc(binary_address),
         {:ok, %{test_only: test_only, bounceable: bounceable}} <- check_tag(tag) do
      workchain =
        if workchain == 0xFF do
          -1
        else
          workchain
        end

      {:ok,
       %__MODULE__{test_only: test_only, bounceable: bounceable, workchain: workchain, hash: hash}}
    end
  end

  def friendly_address(%Wallet{} = wallet, params \\ []) do
    url_safe = Keyword.get(params, :url_safe, true)
    bounceable = Keyword.get(params, :bounceable, true)
    test_only = Keyword.get(params, :test_only, false)

    tag =
      if bounceable do
        @bounceable_tag
      else
        @non_bounceable_tag
      end

    tag =
      if test_only do
        tag ||| @test_flag
      else
        tag
      end

    hash = Wallet.hash(wallet)

    address = <<tag, wallet.workchain>> <> hash
    checksum = Crc16.calc(address)

    address_with_checksum = address <> checksum

    if url_safe do
      address_with_checksum
      |> Base.encode64()
      |> String.replace("+", "-")
      |> String.replace("/", "_")
    else
      Base.encode64(address_with_checksum)
    end
  end

  defp decode_base64(address_str) do
    case address_str
         |> String.replace("-", "+")
         |> String.replace("_", "/")
         |> Base.decode64() do
      {:ok, decoded} -> {:ok, decoded}
      _error -> {:error, :invalid_base64}
    end
  end

  def check_length(address_binary) when byte_size(address_binary) == 36, do: :ok
  def check_length(_address_binary), do: {:error, :invalid_length}

  def check_crc(<<address::binary-size(34), checksum_code::binary-size(2)>>) do
    if Crc16.calc(address) == checksum_code do
      {:ok, address}
    else
      {:error, :invalid_crc}
    end
  end

  def check_tag(tag) do
    {tag, test_only} =
      if (tag &&& @test_flag) > 0 do
        tag = Bitwise.bxor(tag, @test_flag)

        {tag, true}
      else
        {tag, false}
      end

    if tag != @bounceable_tag && tag != @non_bounceable_tag do
      {:error, :invalid_tag}
    else
      {:ok, %{test_only: test_only, bounceable: tag == @bounceable_tag}}
    end
  end
end
