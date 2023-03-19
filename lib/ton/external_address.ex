defmodule Ton.ExternalAddress do
  @type t :: %__MODULE__{
          value: integer(),
          bits: non_neg_integer()
        }

  defstruct [:value, :bits]
end
