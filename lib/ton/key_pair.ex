defmodule Ton.KeyPair do
  @moduledoc """
  Pair of public and secret keys used for wallet operations
  """
  defstruct [:secret_key, :public_key]

  @type t :: %__MODULE__{
          secret_key: binary(),
          public_key: binary()
        }

  @spec new(binary(), binary()) :: t()
  def new(secret_key, public_key)
      when byte_size(secret_key) == 64 and byte_size(public_key) == 32 do
    %__MODULE__{
      secret_key: secret_key,
      public_key: public_key
    }
  end
end
