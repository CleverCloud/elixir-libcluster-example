defmodule DemoWeb.ErrorHTML do
  use DemoWeb, :html

  def render("404.html", _assigns), do: "Page not found"
  def render("500.html", _assigns), do: "Internal server error"
  def render(template, _assigns), do: Phoenix.Controller.status_message_from_template(template)
end
