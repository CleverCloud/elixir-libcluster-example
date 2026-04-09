defmodule DemoWeb.ClusterController do
  use DemoWeb, :controller

  def index(conn, _params) do
    current = node()
    peers = Node.list()

    case get_format(conn) do
      "json" ->
        json(conn, %{
          node: current,
          peers: Enum.map(peers, &to_string/1),
          total: length(peers) + 1
        })

      _ ->
        render(conn, :index, current_node: current, peers: peers)
    end
  end
end
