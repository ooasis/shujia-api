defmodule SJ.Enums do
  import EctoEnum

  defenum Role, :enum_role, [:admin, :librarian, :member]
  defenum Language, :enum_lang, [:en, :cn, :sc, :tc]
  defenum Format, :enum_format, [:book, :audio, :video]

end