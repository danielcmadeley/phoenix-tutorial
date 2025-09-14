defmodule PhoenixTutorialWeb.PageController do
  use PhoenixTutorialWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
