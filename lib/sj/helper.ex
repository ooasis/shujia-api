defmodule SJ.Helpers do

  def is_blank(s) do
    is_nil(s) or s == ""
  end

  def get_or_empty(m, attr) do
    if is_nil(m), do: "", else: Map.get(m, attr, "")
  end

  def language_opts() do
    [
      %{id: :cn, name: "Chinese"},
      %{id: :en, name: "English"},
      %{id: :tc, name: "Traditional Chinese"},
      %{id: :sc, name: "Simplified Chinese"}
    ]
  end

  def format_opts() do
    [%{id: :book, name: "Book"}, %{id: :audio, name: "Audio"}, %{id: :vedio, name: "Vedio"}]
  end

  def role_opts() do
    [%{id: :admin, name: "Admin"}, %{id: :librarian, name: "Librarian"}, %{id: :member, name: "Member"}]
  end

end