defmodule TonTest do
  use ExUnit.Case
  doctest Ton

  describe "mnemonic_to_entropy/2" do
    test "converts mnemonic to entropy" do
      mnemonic =
        "about about about about about about about about about about about about about about about about about about about about about about about about"

      assert <<207, 159, 229, 215, 122, 194, 60, 170, 203, 21, 77, 169, 64, 28, 145, 253, 89, 172,
               192, 117, 44, 37, 103, 174, 189, 137, 144, 113, 57, 96, 67, 66, 99, 217, 176, 3,
               24, 3, 139, 173, 117, 211, 99, 101, 115, 199, 191, 252, 127, 197, 27, 203, 220,
               217, 26, 35, 202, 189, 143, 94, 138, 185, 127,
               179>> = entropy = Ton.mnemonic_to_entropy(mnemonic)

      assert "cf9fe5d77ac23caacb154da9401c91fd59acc0752c2567aebd8990713960434263d9b00318038bad75d3636573c7bffc7fc51bcbdcd91a23cabd8f5e8ab97fb3" =
               Base.encode16(entropy, case: :lower)
    end

    test "converts mnemonic with password to entropy" do
      mnemonic =
        "about about about about about about about about about about about about about about about about about about about about about about about about"

      password = "password"

      assert "893c3359695c384eafb038ba1a144917366b3e1a82c0f1c7755a5c0e9ec3967f53bbebb49b4c1bba4f350d08bc74fcca8c5aee3934d99f2c8d187ef09ccaee19" =
               mnemonic
               |> Ton.mnemonic_to_entropy(password)
               |> Base.encode16(case: :lower)
    end
  end
end
