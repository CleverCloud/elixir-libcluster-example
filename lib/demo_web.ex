defmodule DemoWeb do
  @moduledoc """
  Module racine de DemoWeb.
  Fournit les macros `use DemoWeb, :controller`, `use DemoWeb, :html`, etc.
  """

  def static_paths, do: ~w(favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: DemoWeb.Layouts]

      import Plug.Conn
    end
  end

  def html do
    quote do
      use Phoenix.Component
      import Phoenix.HTML
      import Phoenix.Controller, only: [get_csrf_token: 0]
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
