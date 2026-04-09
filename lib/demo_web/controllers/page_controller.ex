defmodule DemoWeb.PageController do
  use DemoWeb, :controller

  def index(conn, _params) do
    render(conn, :home, node: node())
  end
end
