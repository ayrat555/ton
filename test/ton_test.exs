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

  describe "mnemonic_to_seed/2" do
    test "converts mnemonic to seed" do
      mnemonic =
        "about about about about about about about about about about about about about about about about about about about about about about about about"

      assert <<216, 145, 38, 65, 213, 88, 1, 110, 133, 87, 170, 172, 147, 33, 96, 73, 164, 121,
               52, 37, 94, 100, 25, 147, 124, 8, 232, 161, 104, 122, 232,
               44>> = seed = Ton.mnemonic_to_seed(mnemonic)

      assert "d8912641d558016e8557aaac93216049a47934255e6419937c08e8a1687ae82c" =
               Base.encode16(seed, case: :lower)
    end

    test "converts mnemonic with password to seed" do
      mnemonic =
        "about about about about about about about about about about about about about about about about about about about about about about about about"

      password = "password"

      assert <<35, 167, 22, 244, 245, 19, 147, 41, 251, 239, 17, 2, 254, 103, 119, 222, 122, 20,
               84, 57, 242, 193, 60, 46, 85, 100, 179, 72, 115, 100, 229,
               251>> = seed = Ton.mnemonic_to_seed(mnemonic, password)

      assert "23a716f4f5139329fbef1102fe6777de7a145439f2c13c2e5564b3487364e5fb" =
               Base.encode16(seed, case: :lower)
    end
  end
end
