defmodule AcademyAttendance.Courses do
  @moduledoc """
  The Courses context for managing courses and enrollment.
  """

  alias AcademyAttendance.Courses.Course
  alias AcademyAttendance.Accounts

  # In-memory storage (would be replaced with database in production)
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{courses: %{}}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @doc """
  Creates a new course with a head teacher.
  Only admins can perform this operation.
  """
  def create_course(attrs, created_by_user_id) do
    GenServer.call(__MODULE__, {:create_course, attrs, created_by_user_id})
  end

  @doc """
  Gets a course by ID.
  """
  def get_course(id) do
    GenServer.call(__MODULE__, {:get_course, id})
  end

  @doc """
  Lists all courses.
  """
  def list_courses do
    GenServer.call(__MODULE__, :list_courses)
  end

  @doc """
  Lists courses where the user is a head teacher.
  """
  def list_courses_for_head_teacher(head_teacher_id) do
    GenServer.call(__MODULE__, {:list_courses_for_head_teacher, head_teacher_id})
  end

  @doc """
  Lists courses where the user is a teacher.
  """
  def list_courses_for_teacher(teacher_id) do
    GenServer.call(__MODULE__, {:list_courses_for_teacher, teacher_id})
  end

  @doc """
  Lists courses where the user is a student.
  """
  def list_courses_for_student(student_id) do
    GenServer.call(__MODULE__, {:list_courses_for_student, student_id})
  end

  @doc """
  Updates a course.
  """
  def update_course(id, attrs, updated_by_user_id) do
    GenServer.call(__MODULE__, {:update_course, id, attrs, updated_by_user_id})
  end

  @doc """
  Adds a teacher to a course.
  Only the head teacher or admin can perform this operation.
  """
  def add_teacher_to_course(course_id, teacher_id, added_by_user_id) do
    GenServer.call(__MODULE__, {:add_teacher_to_course, course_id, teacher_id, added_by_user_id})
  end

  @doc """
  Removes a teacher from a course.
  """
  def remove_teacher_from_course(course_id, teacher_id, removed_by_user_id) do
    GenServer.call(__MODULE__, {:remove_teacher_from_course, course_id, teacher_id, removed_by_user_id})
  end

  @doc """
  Adds a student to a course.
  """
  def add_student_to_course(course_id, student_id, added_by_user_id) do
    GenServer.call(__MODULE__, {:add_student_to_course, course_id, student_id, added_by_user_id})
  end

  @doc """
  Removes a student from a course.
  """
  def remove_student_from_course(course_id, student_id, removed_by_user_id) do
    GenServer.call(__MODULE__, {:remove_student_from_course, course_id, student_id, removed_by_user_id})
  end

  @doc """
  Deletes a course.
  """
  def delete_course(id, deleted_by_user_id) do
    GenServer.call(__MODULE__, {:delete_course, id, deleted_by_user_id})
  end

  # GenServer callbacks

  @impl true
  def handle_call({:create_course, attrs, created_by_user_id}, _from, state) do
    created_by_user = Accounts.get_user(created_by_user_id)
    
    case created_by_user do
      nil ->
        {:reply, {:error, ["User not found"]}, state}
      
      user ->
        if user.role == :admin do
          course = Course.new(attrs)
          
          case Course.validate(course) do
            {:ok, valid_course} ->
              new_state = put_in(state.courses[valid_course.id], valid_course)
              {:reply, {:ok, valid_course}, new_state}
            
            {:error, errors} ->
              {:reply, {:error, errors}, state}
          end
        else
          {:reply, {:error, ["Only admins can create courses"]}, state}
        end
    end
  end

  @impl true
  def handle_call({:get_course, id}, _from, state) do
    course = Map.get(state.courses, id)
    {:reply, course, state}
  end

  @impl true
  def handle_call(:list_courses, _from, state) do
    courses = Map.values(state.courses)
    {:reply, courses, state}
  end

  @impl true
  def handle_call({:list_courses_for_head_teacher, head_teacher_id}, _from, state) do
    courses = Map.values(state.courses) 
              |> Enum.filter(fn c -> c.head_teacher_id == head_teacher_id end)
    {:reply, courses, state}
  end

  @impl true
  def handle_call({:list_courses_for_teacher, teacher_id}, _from, state) do
    courses = Map.values(state.courses) 
              |> Enum.filter(fn c -> teacher_id in c.teacher_ids end)
    {:reply, courses, state}
  end

  @impl true
  def handle_call({:list_courses_for_student, student_id}, _from, state) do
    courses = Map.values(state.courses) 
              |> Enum.filter(fn c -> student_id in c.student_ids end)
    {:reply, courses, state}
  end

  @impl true
  def handle_call({:update_course, id, attrs, updated_by_user_id}, _from, state) do
    case {Map.get(state.courses, id), Accounts.get_user(updated_by_user_id)} do
      {nil, _} ->
        {:reply, {:error, ["Course not found"]}, state}
      
      {_, nil} ->
        {:reply, {:error, ["User not found"]}, state}
      
      {course, user} ->
        if can_manage_course?(course, user) do
          updated_course = Course.update(course, attrs)
          
          case Course.validate(updated_course) do
            {:ok, valid_course} ->
              new_state = put_in(state.courses[id], valid_course)
              {:reply, {:ok, valid_course}, new_state}
            
            {:error, errors} ->
              {:reply, {:error, errors}, state}
          end
        else
          {:reply, {:error, ["Insufficient permissions to update course"]}, state}
        end
    end
  end

  @impl true
  def handle_call({:add_teacher_to_course, course_id, teacher_id, added_by_user_id}, _from, state) do
    with course when not is_nil(course) <- Map.get(state.courses, course_id),
         user when not is_nil(user) <- Accounts.get_user(added_by_user_id),
         teacher when not is_nil(teacher) <- Accounts.get_user(teacher_id),
         true <- can_manage_course?(course, user),
         true <- teacher.role == :teacher do
      
      updated_course = Course.add_teacher(course, teacher_id)
      new_state = put_in(state.courses[course_id], updated_course)
      {:reply, {:ok, updated_course}, new_state}
    else
      nil -> {:reply, {:error, ["Course, user, or teacher not found"]}, state}
      false -> {:reply, {:error, ["Insufficient permissions or invalid teacher role"]}, state}
    end
  end

  @impl true
  def handle_call({:remove_teacher_from_course, course_id, teacher_id, removed_by_user_id}, _from, state) do
    with course when not is_nil(course) <- Map.get(state.courses, course_id),
         user when not is_nil(user) <- Accounts.get_user(removed_by_user_id),
         true <- can_manage_course?(course, user) do
      
      updated_course = Course.remove_teacher(course, teacher_id)
      new_state = put_in(state.courses[course_id], updated_course)
      {:reply, {:ok, updated_course}, new_state}
    else
      nil -> {:reply, {:error, ["Course or user not found"]}, state}
      false -> {:reply, {:error, ["Insufficient permissions"]}, state}
    end
  end

  @impl true
  def handle_call({:add_student_to_course, course_id, student_id, added_by_user_id}, _from, state) do
    with course when not is_nil(course) <- Map.get(state.courses, course_id),
         user when not is_nil(user) <- Accounts.get_user(added_by_user_id),
         student when not is_nil(student) <- Accounts.get_user(student_id),
         true <- can_manage_course?(course, user),
         true <- student.role == :student do
      
      updated_course = Course.add_student(course, student_id)
      new_state = put_in(state.courses[course_id], updated_course)
      {:reply, {:ok, updated_course}, new_state}
    else
      nil -> {:reply, {:error, ["Course, user, or student not found"]}, state}
      false -> {:reply, {:error, ["Insufficient permissions or invalid student role"]}, state}
    end
  end

  @impl true
  def handle_call({:remove_student_from_course, course_id, student_id, removed_by_user_id}, _from, state) do
    with course when not is_nil(course) <- Map.get(state.courses, course_id),
         user when not is_nil(user) <- Accounts.get_user(removed_by_user_id),
         true <- can_manage_course?(course, user) do
      
      updated_course = Course.remove_student(course, student_id)
      new_state = put_in(state.courses[course_id], updated_course)
      {:reply, {:ok, updated_course}, new_state}
    else
      nil -> {:reply, {:error, ["Course or user not found"]}, state}
      false -> {:reply, {:error, ["Insufficient permissions"]}, state}
    end
  end

  @impl true
  def handle_call({:delete_course, id, deleted_by_user_id}, _from, state) do
    case {Map.get(state.courses, id), Accounts.get_user(deleted_by_user_id)} do
      {nil, _} ->
        {:reply, {:error, ["Course not found"]}, state}
      
      {_, nil} ->
        {:reply, {:error, ["User not found"]}, state}
      
      {course, user} ->
        if user.role == :admin or Course.can_manage?(course, user.id) do
          new_state = %{state | courses: Map.delete(state.courses, id)}
          {:reply, {:ok, course}, new_state}
        else
          {:reply, {:error, ["Insufficient permissions to delete course"]}, state}
        end
    end
  end

  defp can_manage_course?(course, user) do
    user.role == :admin or Course.can_manage?(course, user.id)
  end
end