defmodule Ton.CommentTest do
  use ExUnit.Case

  alias Ton.Cell
  alias Ton.Comment

  describe "serialize/1" do
    test "serializes a comment" do
      comment = "123e4567-e89b-12d3-a456-426614174000"

      assert %Ton.Cell{
               refs: [],
               data: _data,
               kind: :ordinary
             } = cell = Comment.serialize(comment)

      assert "a81c67f34212e38a2c3e64bc8d9d4c184be63b2e7a2a9fab38de3abd9ae5c895" ==
               cell |> Cell.hash() |> Base.encode16(case: :lower)
    end

    test "serializes a big comment" do
      comment =
        "I cared more for your happiness than your knowing the truth, more for your peace of mind than my plan, more for your life than the lives that might be lost if the plan failed."

      assert %Ton.Cell{
               refs: [%Ton.Cell{refs: []}],
               data: _data,
               kind: :ordinary
             } = cell = Comment.serialize(comment)

      assert "1a04a7a85212d8e617edfbab2368843a60ef42542524a8e888657d96fd65e395" ==
               cell |> Cell.hash() |> Base.encode16(case: :lower)
    end
  end
end
