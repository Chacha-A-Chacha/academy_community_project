defmodule AcademyAttendance.Accounts do
  @moduledoc """
  The Accounts context for managing users and authentication.
  """

  alias AcademyAttendance.Accounts.User

  # In-memory storage (would be replaced with database in production)
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{users: %{}}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @doc """
  Creates a new user.
  """
  def create_user(attrs) do
    user = User.new(attrs)
    
    case User.validate(user) do
      {:ok, valid_user} ->
        GenServer.call(__MODULE__, {:create_user, valid_user})
      
      {:error, errors} ->
        {:error, errors}
    end
  end

  @doc """
  Gets a user by ID.
  """
  def get_user(id) do
    GenServer.call(__MODULE__, {:get_user, id})
  end

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) do
    GenServer.call(__MODULE__, {:get_user_by_email, email})
  end

  @doc """
  Gets a user by student ID.
  """
  def get_user_by_student_id(student_id) do
    GenServer.call(__MODULE__, {:get_user_by_student_id, student_id})
  end

  @doc """
  Lists all users.
  """
  def list_users do
    GenServer.call(__MODULE__, :list_users)
  end

  @doc """
  Lists users by role.
  """
  def list_users_by_role(role) do
    GenServer.call(__MODULE__, {:list_users_by_role, role})
  end

  @doc """
  Updates a user.
  """
  def update_user(id, attrs) do
    GenServer.call(__MODULE__, {:update_user, id, attrs})
  end

  @doc """
  Deletes a user.
  """
  def delete_user(id) do
    GenServer.call(__MODULE__, {:delete_user, id})
  end

  @doc """
  Creates an admin user and a head teacher simultaneously.
  This operation is atomic - either both succeed or both fail.
  """
  def create_admin_and_head_teacher(admin_attrs, head_teacher_attrs) do
    GenServer.call(__MODULE__, {:create_admin_and_head_teacher, admin_attrs, head_teacher_attrs})
  end

  # GenServer callbacks

  @impl true
  def handle_call({:create_user, user}, _from, state) do
    case Map.get(state.users, user.id) do
      nil ->
        new_state = put_in(state.users[user.id], user)
        {:reply, {:ok, user}, new_state}
      
      _existing ->
        {:reply, {:error, ["User with this ID already exists"]}, state}
    end
  end

  @impl true
  def handle_call({:get_user, id}, _from, state) do
    user = Map.get(state.users, id)
    {:reply, user, state}
  end

  @impl true
  def handle_call({:get_user_by_email, email}, _from, state) do
    user = Enum.find(Map.values(state.users), fn u -> u.email == email end)
    {:reply, user, state}
  end

  @impl true
  def handle_call({:get_user_by_student_id, student_id}, _from, state) do
    user = Enum.find(Map.values(state.users), fn u -> u.student_id == student_id end)
    {:reply, user, state}
  end

  @impl true
  def handle_call(:list_users, _from, state) do
    users = Map.values(state.users)
    {:reply, users, state}
  end

  @impl true
  def handle_call({:list_users_by_role, role}, _from, state) do
    users = Map.values(state.users) |> Enum.filter(fn u -> u.role == role end)
    {:reply, users, state}
  end

  @impl true
  def handle_call({:update_user, id, attrs}, _from, state) do
    case Map.get(state.users, id) do
      nil ->
        {:reply, {:error, ["User not found"]}, state}
      
      user ->
        updated_user = User.update(user, attrs)
        
        case User.validate(updated_user) do
          {:ok, valid_user} ->
            new_state = put_in(state.users[id], valid_user)
            {:reply, {:ok, valid_user}, new_state}
          
          {:error, errors} ->
            {:reply, {:error, errors}, state}
        end
    end
  end

  @impl true
  def handle_call({:delete_user, id}, _from, state) do
    case Map.get(state.users, id) do
      nil ->
        {:reply, {:error, ["User not found"]}, state}
      
      user ->
        new_state = %{state | users: Map.delete(state.users, id)}
        {:reply, {:ok, user}, new_state}
    end
  end

  @impl true
  def handle_call({:create_admin_and_head_teacher, admin_attrs, head_teacher_attrs}, _from, state) do
    admin = User.new(Map.put(admin_attrs, :role, :admin))
    head_teacher = User.new(Map.put(head_teacher_attrs, :role, :head_teacher))
    
    with {:ok, valid_admin} <- User.validate(admin),
         {:ok, valid_head_teacher} <- User.validate(head_teacher),
         nil <- Map.get(state.users, valid_admin.id),
         nil <- Map.get(state.users, valid_head_teacher.id) do
      
      new_state = state
                  |> put_in([:users, valid_admin.id], valid_admin)
                  |> put_in([:users, valid_head_teacher.id], valid_head_teacher)
      
      {:reply, {:ok, {valid_admin, valid_head_teacher}}, new_state}
    else
      {:error, errors} ->
        {:reply, {:error, errors}, state}
      
      _existing_user ->
        {:reply, {:error, ["One or both users already exist"]}, state}
    end
  end
end