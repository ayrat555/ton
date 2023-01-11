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

      assert "88ddc65734637344cb7562752958c773f21ebe6234462e8bec5ded773b8dc667" ==
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

      assert "7c822fd0818a94edcea590e647e7b5afe3f2d5c9fc44ad934eecf1aa16b30032" ==
               cell |> Cell.hash() |> Base.encode16(case: :lower)
    end
  end
end
