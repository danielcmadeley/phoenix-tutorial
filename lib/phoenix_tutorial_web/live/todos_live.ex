defmodule PhoenixTutorialWeb.TodosLive do
  use PhoenixTutorialWeb, :live_view

  alias PhoenixTutorial.Todos
  alias PhoenixTutorial.Todos.Todo

  def mount(_params, _session, socket) do
    todos = Todos.list_todos()

    socket =
      socket
      |> assign(:page_title, "Todo List")
      |> assign(:todos_empty?, todos == [])
      |> assign(:total_count, length(todos))
      |> assign(:completed_count, Enum.count(todos, & &1.completed))
      |> assign(:pending_count, Enum.count(todos, &(!&1.completed)))
      |> assign(:editing_todo, nil)
      |> assign(:edit_form, nil)
      |> assign(:form, to_form(Todos.change_todo(%Todo{})))
      |> stream(:todos, todos)

    {:ok, socket}
  end

  def handle_event("validate", %{"todo" => todo_params}, socket) do
    changeset =
      %Todo{}
      |> Todos.change_todo(todo_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("create", %{"todo" => todo_params}, socket) do
    case Todos.create_todo(todo_params) do
      {:ok, todo} ->
        socket =
          socket
          |> put_flash(:info, "Todo created successfully!")
          |> assign(:form, to_form(Todos.change_todo(%Todo{})))
          |> stream_insert(:todos, todo, at: 0)
          |> assign(:todos_empty?, false)
          |> update(:total_count, &(&1 + 1))
          |> update(:pending_count, &(&1 + 1))

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("edit", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)
    changeset = Todos.change_todo(todo)

    socket =
      socket
      |> assign(:editing_todo, todo)
      |> assign(:edit_form, to_form(changeset))

    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)
    {:ok, _} = Todos.delete_todo(todo)

    todos = Todos.list_todos()

    socket =
      socket
      |> put_flash(:info, "Todo deleted successfully!")
      |> stream_delete(:todos, todo)
      |> assign(:todos_empty?, todos == [])
      |> update(:total_count, &(&1 - 1))
      |> update(if(todo.completed, do: :completed_count, else: :pending_count), &(&1 - 1))

    {:noreply, socket}
  end

  def handle_event("cancel_edit", _params, socket) do
    socket =
      socket
      |> assign(:editing_todo, nil)
      |> assign(:edit_form, nil)

    {:noreply, socket}
  end

  def handle_event("update", %{"todo" => todo_params}, socket) do
    todo = socket.assigns.editing_todo

    case Todos.update_todo(todo, todo_params) do
      {:ok, updated_todo} ->
        socket =
          socket
          |> put_flash(:info, "Todo updated successfully!")
          |> assign(:editing_todo, nil)
          |> assign(:edit_form, nil)
          |> stream_insert(:todos, updated_todo)

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, edit_form: to_form(changeset))}
    end
  end

  def handle_event("toggle_complete", %{"id" => id}, socket) do
    todo = Todos.get_todo!(id)

    case Todos.update_todo(todo, %{completed: !todo.completed}) do
      {:ok, updated_todo} ->
        socket =
          socket
          |> stream_insert(:todos, updated_todo)
          |> update(:completed_count, fn count ->
            if updated_todo.completed, do: count + 1, else: count - 1
          end)
          |> update(:pending_count, fn count ->
            if updated_todo.completed, do: count - 1, else: count + 1
          end)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update todo")}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-4xl mx-auto px-4 py-8">
        <!-- Header -->
        <div class="mb-8 text-center">
          <h1 class="text-4xl font-bold text-gray-900 mb-2">Todo List</h1>
          <p class="text-gray-600">Stay organized and get things done</p>
        </div>
        
    <!-- Create Todo Form -->
        <div class="bg-white rounded-lg shadow-md p-6 mb-8 border border-gray-200">
          <h2 class="text-xl font-semibold text-gray-800 mb-4">Add New Todo</h2>

          <.form
            for={@form}
            id="todo-form"
            phx-change="validate"
            phx-submit="create"
            class="space-y-4"
          >
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div class="md:col-span-2">
                <.input
                  field={@form[:title]}
                  type="text"
                  placeholder="What needs to be done?"
                  class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
              <button
                type="submit"
                class="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-6 rounded-lg transition-colors duration-200 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
              >
                <.icon name="hero-plus" class="w-5 h-5 inline mr-2" /> Add Todo
              </button>
            </div>

            <div>
              <.input
                field={@form[:description]}
                type="textarea"
                placeholder="Additional details (optional)"
                class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 resize-none"
                rows="2"
              />
            </div>
          </.form>
        </div>
        
    <!-- Todo List -->
        <div class="bg-white rounded-lg shadow-md border border-gray-200 overflow-hidden">
          <div id="todos" phx-update="stream" class="divide-y divide-gray-200">
            <!-- Empty State -->
            <div class="hidden only:block p-12 text-center text-gray-500">
              <.icon name="hero-clipboard-document-list" class="w-16 h-16 mx-auto mb-4 text-gray-300" />
              <h3 class="text-lg font-medium text-gray-900 mb-2">No todos yet</h3>
              <p class="text-gray-600">Get started by adding your first todo above.</p>
            </div>
            
    <!-- Todo Items -->
            <div
              :for={{id, todo} <- @streams.todos}
              id={id}
              class="p-4 hover:bg-gray-50 transition-colors duration-150"
            >
              <div :if={@editing_todo && @editing_todo.id == todo.id} class="space-y-4">
                <!-- Edit Form -->
                <.form
                  for={@edit_form}
                  id={"edit-todo-#{todo.id}"}
                  phx-submit="update"
                  class="space-y-4"
                >
                  <.input
                    field={@edit_form[:title]}
                    type="text"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  />
                  <.input
                    field={@edit_form[:description]}
                    type="textarea"
                    placeholder="Description (optional)"
                    class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-2 focus:ring-blue-500 focus:border-blue-500 resize-none"
                    rows="2"
                  />
                  <div class="flex space-x-2">
                    <button
                      type="submit"
                      class="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors duration-200"
                    >
                      <.icon name="hero-check" class="w-4 h-4 inline mr-1" /> Save
                    </button>
                    <button
                      type="button"
                      phx-click="cancel_edit"
                      class="bg-gray-600 hover:bg-gray-700 text-white px-4 py-2 rounded-md text-sm font-medium transition-colors duration-200"
                    >
                      Cancel
                    </button>
                  </div>
                </.form>
              </div>

              <div
                :if={!@editing_todo || @editing_todo.id != todo.id}
                class="flex items-start space-x-3"
              >
                <!-- Checkbox -->
                <button
                  phx-click="toggle_complete"
                  phx-value-id={todo.id}
                  class={[
                    "mt-1 flex-shrink-0 w-5 h-5 rounded border-2 transition-all duration-200 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2",
                    todo.completed && "bg-green-500 border-green-500 text-white",
                    !todo.completed && "border-gray-300 hover:border-gray-400"
                  ]}
                >
                  <.icon :if={todo.completed} name="hero-check" class="w-3 h-3" />
                </button>
                
    <!-- Todo Content -->
                <div class="flex-1 min-w-0">
                  <h3 class={[
                    "text-lg font-medium transition-colors duration-200",
                    todo.completed && "line-through text-gray-500",
                    !todo.completed && "text-gray-900"
                  ]}>
                    {todo.title}
                  </h3>
                  <p
                    :if={todo.description}
                    class={[
                      "mt-1 text-sm",
                      todo.completed && "text-gray-400",
                      !todo.completed && "text-gray-600"
                    ]}
                  >
                    {todo.description}
                  </p>
                  <p class="mt-1 text-xs text-gray-400">
                    Created {Calendar.strftime(todo.inserted_at, "%B %d, %Y at %I:%M %p")}
                  </p>
                </div>
                
    <!-- Actions -->
                <div class="flex-shrink-0 flex space-x-2">
                  <button
                    phx-click="edit"
                    phx-value-id={todo.id}
                    class="text-blue-600 hover:text-blue-800 transition-colors duration-200 p-1"
                  >
                    <.icon name="hero-pencil" class="w-4 h-4" />
                    <span class="sr-only">Edit</span>
                  </button>
                  <button
                    phx-click="delete"
                    phx-value-id={todo.id}
                    data-confirm="Are you sure you want to delete this todo?"
                    class="text-red-600 hover:text-red-800 transition-colors duration-200 p-1"
                  >
                    <.icon name="hero-trash" class="w-4 h-4" />
                    <span class="sr-only">Delete</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Stats -->
        <div class="mt-8 bg-gray-50 rounded-lg p-6 border border-gray-200">
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-center">
            <div>
              <p class="text-2xl font-bold text-blue-600" id="total-todos">
                {@total_count}
              </p>
              <p class="text-sm text-gray-600">Total Todos</p>
            </div>
            <div>
              <p class="text-2xl font-bold text-green-600" id="completed-todos">
                {@completed_count}
              </p>
              <p class="text-sm text-gray-600">Completed</p>
            </div>
            <div>
              <p class="text-2xl font-bold text-yellow-600" id="pending-todos">
                {@pending_count}
              </p>
              <p class="text-sm text-gray-600">Pending</p>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
