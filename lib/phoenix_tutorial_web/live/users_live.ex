defmodule PhoenixTutorialWeb.UsersLive do
  use PhoenixTutorialWeb, :live_view

  def mount(_params, _session, socket) do
    users = [
      %{id: 1, name: "John Doe", email: "john@example.com"},
      %{id: 2, name: "Jane Smith", email: "jane@example.com"},
      %{id: 3, name: "Bob Johnson", email: "bob@example.com"},
      %{id: 4, name: "Alice Brown", email: "alice@example.com"}
    ]

    {:ok, assign(socket, :users, users)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-4xl mx-auto p-6">
        <h1 class="text-3xl font-bold text-gray-900 mb-8">Users</h1>

        <div class="bg-white shadow-sm rounded-lg border border-gray-200">
          <div class="px-6 py-4 border-b border-gray-200">
            <h2 class="text-lg font-medium text-gray-900">User List</h2>
            <p class="text-sm text-gray-600">A collection of registered users</p>
          </div>

          <div class="divide-y divide-gray-200">
            <%= for user <- @users do %>
              <div class="px-6 py-4 hover:bg-gray-50 transition-colors">
                <div class="flex items-center justify-between">
                  <div class="flex-1">
                    <h3 class="text-lg font-medium text-gray-900">{user.name}</h3>
                    <p class="text-sm text-gray-600">{user.email}</p>
                  </div>
                  <div class="flex items-center space-x-2">
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                      Active
                    </span>
                    <span class="text-sm text-gray-500">ID: {user.id}</span>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <div class="mt-6 flex justify-between items-center">
          <p class="text-sm text-gray-600">
            Showing {length(@users)} users
          </p>
          <button class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors">
            Add New User
          </button>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
