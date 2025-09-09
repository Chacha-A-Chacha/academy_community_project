defmodule AcademyAttendance.Courses.Course do
  @moduledoc """
  Course schema for managing academy courses.
  Each course has a head teacher and can have multiple teachers and students.
  """

  defstruct [:id, :name, :description, :head_teacher_id, :teacher_ids, :student_ids, :inserted_at, :updated_at]

  @type t :: %__MODULE__{
    id: String.t(),
    name: String.t(),
    description: String.t(),
    head_teacher_id: String.t(),
    teacher_ids: [String.t()],
    student_ids: [String.t()],
    inserted_at: DateTime.t(),
    updated_at: DateTime.t()
  }

  @doc """
  Creates a new course with the given attributes.
  """
  def new(attrs \\ %{}) do
    now = DateTime.utc_now()
    
    %__MODULE__{
      id: generate_id(),
      name: Map.get(attrs, :name, ""),
      description: Map.get(attrs, :description, ""),
      head_teacher_id: Map.get(attrs, :head_teacher_id),
      teacher_ids: Map.get(attrs, :teacher_ids, []),
      student_ids: Map.get(attrs, :student_ids, []),
      inserted_at: now,
      updated_at: now
    }
  end

  @doc """
  Validates course data.
  """
  def validate(%__MODULE__{} = course) do
    errors = []
    
    errors = if String.trim(course.name) == "", do: ["Course name is required" | errors], else: errors
    errors = if is_nil(course.head_teacher_id), do: ["Head teacher is required" | errors], else: errors
    
    case errors do
      [] -> {:ok, course}
      _ -> {:error, errors}
    end
  end

  @doc """
  Updates course attributes.
  """
  def update(%__MODULE__{} = course, attrs) do
    %{course |
      name: Map.get(attrs, :name, course.name),
      description: Map.get(attrs, :description, course.description),
      head_teacher_id: Map.get(attrs, :head_teacher_id, course.head_teacher_id),
      teacher_ids: Map.get(attrs, :teacher_ids, course.teacher_ids),
      student_ids: Map.get(attrs, :student_ids, course.student_ids),
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Adds a teacher to the course.
  """
  def add_teacher(%__MODULE__{} = course, teacher_id) do
    if teacher_id in course.teacher_ids do
      course
    else
      %{course | 
        teacher_ids: [teacher_id | course.teacher_ids],
        updated_at: DateTime.utc_now()
      }
    end
  end

  @doc """
  Removes a teacher from the course.
  """
  def remove_teacher(%__MODULE__{} = course, teacher_id) do
    %{course | 
      teacher_ids: List.delete(course.teacher_ids, teacher_id),
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Adds a student to the course.
  """
  def add_student(%__MODULE__{} = course, student_id) do
    if student_id in course.student_ids do
      course
    else
      %{course | 
        student_ids: [student_id | course.student_ids],
        updated_at: DateTime.utc_now()
      }
    end
  end

  @doc """
  Removes a student from the course.
  """
  def remove_student(%__MODULE__{} = course, student_id) do
    %{course | 
      student_ids: List.delete(course.student_ids, student_id),
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Checks if a user has access to manage this course.
  """
  def can_manage?(%__MODULE__{head_teacher_id: head_teacher_id}, user_id) when head_teacher_id == user_id, do: true
  def can_manage?(_, _), do: false

  @doc """
  Checks if a user is associated with this course (as teacher or student).
  """
  def has_access?(%__MODULE__{} = course, user_id) do
    course.head_teacher_id == user_id or 
    user_id in course.teacher_ids or 
    user_id in course.student_ids
  end

  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.encode64() |> String.replace(~r/[^A-Za-z0-9]/, "")
  end
end