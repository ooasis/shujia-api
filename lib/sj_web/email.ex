defmodule SJWeb.Email do
  use Bamboo.Phoenix, view: SJWeb.EmailView

  @from System.get_env("EMAIL_FROM") || ""
  @host System.get_env("HOST") || "localhost"
  @port System.get_env("PORT") || "4000"
 
  defp welcome_text_email(new_user) do
    new_email()
    |> to(new_user.email)
    |> from(@from)
    |> subject("Welcome!")
    |> put_text_layout({SJWeb.LayoutView, "email.text"})
    |> render("welcome.text", user: new_user, url: "http://#{@host}:#{@port}")
  end

  def welcome_html_email(new_user) do
    new_user
    |> welcome_text_email()
    |> put_html_layout({SJWeb.LayoutView, "email.html"})
    |> render("welcome.html", user: new_user, url: "http://#{@host}:#{@port}")
  end

  defp password_recover_text_email(user) do
    new_email()
    |> to(user.email)
    |> from(@from)
    |> subject("Password recovery!")
    |> put_text_layout({SJWeb.LayoutView, "email.text"})
    |> render("password_recover.text", user: user, url: "http://#{@host}:#{@port}")
  end

  def password_recover_html_email(user) do
    user
    |> password_recover_text_email()
    |> put_html_layout({SJWeb.LayoutView, "email.html"})
    |> render("password_recover.html", user: user, url: "http://#{@host}:#{@port}")
  end
end
