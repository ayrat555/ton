defmodule Ton.Address do
  @moduledoc """
  Functions for parsing, validation and serialization of TON addresses.
  """
  import Bitwise

  alias Ton.Wallet

  @bounceable_tag 0x11
  @non_bounceable_tag 0x51
  @test_flag 0x80

  defstruct [:test_only, :bounceable, :workchain, :hash]

  @type t :: %__MODULE__{
          test_only: boolean(),
          bounceable: boolean(),
          workchain: integer(),
          hash: binary()
        }

  @spec parse(binary()) :: {:ok, t()} | {:error, atom()}
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

  @spec friendly_address(Wallet.t(), Keyword.t()) :: binary()
  def friendly_address(%Wallet{} = wallet, params \\ []) do
    params
    |> Keyword.put(:hash, Wallet.hash(wallet))
    |> Keyword.put(:workchain, wallet.workchain)
    |> do_friendly_address()
  end

  @spec raw_address(Wallet.t()) :: binary()
  def raw_address(%Wallet{} = wallet) do
    hash =
      wallet
      |> Wallet.hash()
      |> Base.encode16(case: :lower)

    "#{wallet.workchain}:#{hash}"
  end

  @spec raw_address_to_friendly_address(binary(), Keyword.t()) :: binary()
  def raw_address_to_friendly_address(raw_address, opts \\ []) do
    [str_workchain | [hex_hash]] = String.split(raw_address, ":")
    {workchain, ""} = Integer.parse(str_workchain)
    hash = Base.decode16!(hex_hash, case: :lower)

    opts
    |> Keyword.put(:hash, hash)
    |> Keyword.put(:workchain, workchain)
    |> do_friendly_address()
  end

  @spec friendly_address_to_raw_address(binary()) :: binary()
  def friendly_address_to_raw_address(address_str) do
    with {:ok, address} <- parse(address_str) do
      encoded_hash = Base.encode16(address.hash, case: :lower)

      "#{address.workchain}:#{encoded_hash}"
    end
  end

  def do_friendly_address(params) do
    hash = Keyword.fetch!(params, :hash)
    workchain = Keyword.fetch!(params, :workchain)
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

    address = <<tag, workchain>> <> hash
    checksum = EvilCrc32c.crc16(address)

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

  defp check_length(address_binary) when byte_size(address_binary) == 36, do: :ok
  defp check_length(_address_binary), do: {:error, :invalid_length}

  defp check_crc(<<address::binary-size(34), checksum_code::binary-size(2)>>) do
    if EvilCrc32c.crc16(address) == checksum_code do
      {:ok, address}
    else
      {:error, :invalid_crc}
    end
  end

  defp check_tag(tag) do
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
