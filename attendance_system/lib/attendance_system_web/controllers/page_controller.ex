defmodule AttendanceSystemWeb.PageController do
  use AttendanceSystemWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
