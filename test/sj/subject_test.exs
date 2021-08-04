defmodule SJ.SubjectTest do
  use SJ.DataCase

  alias SJ.Subject

  @valid_attrs %{name: "same"}
  @invalid_attrs %{email: "sam@google.com"}

  test "changeset with valid attributes" do
    changeset = Subject.changeset(%Subject{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Subject.changeset(%Subject{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "insert new subject if not exists" do
    refute  is_nil(Subject.get_or_insert("art").id)
  end

end