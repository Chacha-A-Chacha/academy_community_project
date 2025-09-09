defmodule AcademyAttendance.Accounts.User do
  @moduledoc """
  User schema with role-based access control.
  Supports Admin, Head Teacher, Teacher, and Student roles.
  """

  defstruct [:id, :name, :email, :student_id, :role, :inserted_at, :updated_at]

  @type role :: :admin | :head_teacher | :teacher | :student

  @type t :: %__MODULE__{
    id: String.t(),
    name: String.t(),
    email: String.t(),
    student_id: String.t() | nil,
    role: role(),
    inserted_at: DateTime.t(),
    updated_at: DateTime.t()
  }

  @roles [:admin, :head_teacher, :teacher, :student]

  def valid_roles, do: @roles

  @doc """
  Creates a new user with the given attributes.
  """
  def new(attrs \\ %{}) do
    now = DateTime.utc_now()
    
    %__MODULE__{
      id: generate_id(),
      name: Map.get(attrs, :name, ""),
      email: Map.get(attrs, :email, ""),
      student_id: Map.get(attrs, :student_id),
      role: Map.get(attrs, :role, :student),
      inserted_at: now,
      updated_at: now
    }
  end

  @doc """
  Validates user data.
  """
  def validate(%__MODULE__{} = user) do
    errors = []
    
    errors = if String.trim(user.name) == "", do: ["Name is required" | errors], else: errors
    errors = if String.trim(user.email) == "", do: ["Email is required" | errors], else: errors
    errors = if user.role not in @roles, do: ["Invalid role" | errors], else: errors
    errors = if user.role == :student and is_nil(user.student_id), 
             do: ["Student ID is required for students" | errors], else: errors
    
    case errors do
      [] -> {:ok, user}
      _ -> {:error, errors}
    end
  end

  @doc """
  Updates user attributes.
  """
  def update(%__MODULE__{} = user, attrs) do
    %{user |
      name: Map.get(attrs, :name, user.name),
      email: Map.get(attrs, :email, user.email),
      student_id: Map.get(attrs, :student_id, user.student_id),
      role: Map.get(attrs, :role, user.role),
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Checks if user has permission for a specific action.
  """
  def has_permission?(%__MODULE__{role: :admin}, _action), do: true
  def has_permission?(%__MODULE__{role: :head_teacher}, action) when action in [:create_course, :manage_course, :add_teacher, :view_attendance], do: true
  def has_permission?(%__MODULE__{role: :teacher}, action) when action in [:mark_attendance, :view_attendance], do: true
  def has_permission?(%__MODULE__{role: :student}, action) when action in [:generate_qr, :view_own_attendance], do: true
  def has_permission?(_, _), do: false

  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.encode64() |> String.replace(~r/[^A-Za-z0-9]/, "")
  end
end