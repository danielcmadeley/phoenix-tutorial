defmodule PhoenixTutorial.Todos do
  @moduledoc """
  The Todos context.
  """

  import Ecto.Query, warn: false
  alias PhoenixTutorial.Repo
  alias PhoenixTutorial.Todos.Todo

  @doc """
  Returns the list of todos.
  """
  def list_todos do
    Repo.all(from t in Todo, order_by: [desc: t.inserted_at])
  end

  @doc """
  Gets a single todo.
  """
  def get_todo!(id), do: Repo.get!(Todo, id)

  @doc """
  Creates a todo.
  """
  def create_todo(attrs \\ %{}) do
    %Todo{}
    |> Todo.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a todo.
  """
  def update_todo(%Todo{} = todo, attrs) do
    todo
    |> Todo.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a todo.
  """
  def delete_todo(%Todo{} = todo) do
    Repo.delete(todo)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking todo changes.
  """
  def change_todo(%Todo{} = todo, attrs \\ %{}) do
    Todo.changeset(todo, attrs)
  end
end
