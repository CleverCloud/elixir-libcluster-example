defmodule Demo.ClusterMonitor do
  @moduledoc """
  GenServer that monitors Erlang node connections and disconnections.

  Subscribes to :nodeup and :nodedown events via :net_kernel.monitor_nodes/1
  and logs them for cluster diagnostics.
  """
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    :net_kernel.monitor_nodes(true, node_type: :all)
    Logger.info("[ClusterMonitor] Started on #{node()}. Current peers: #{inspect(Node.list())}")
    {:ok, %{}}
  end

  @impl true
  def handle_info({:nodeup, node, _info}, state) do
    Logger.info("[ClusterMonitor] nodeup: #{node} | cluster: #{inspect(Node.list())}")
    {:noreply, state}
  end

  @impl true
  def handle_info({:nodedown, node, _info}, state) do
    Logger.warning("[ClusterMonitor] nodedown: #{node} | remaining cluster: #{inspect(Node.list())}")
    {:noreply, state}
  end

  @impl true
  def handle_info(msg, state) do
    Logger.debug("[ClusterMonitor] unexpected message: #{inspect(msg)}")
    {:noreply, state}
  end
end
