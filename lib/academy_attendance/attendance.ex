defmodule AcademyAttendance.Attendance do
  @moduledoc """
  The Attendance context for managing student attendance records.
  """

  alias AcademyAttendance.Attendance.Record
  alias AcademyAttendance.{Accounts, Courses, QRCode}

  # In-memory storage (would be replaced with database in production)
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{records: %{}, qr_codes: %{}}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @doc """
  Marks attendance for a student.
  """
  def mark_attendance(course_id, student_id, status, marked_by_user_id) do
    GenServer.call(__MODULE__, {:mark_attendance, course_id, student_id, status, marked_by_user_id})
  end

  @doc """
  Marks attendance using a QR code.
  """
  def mark_attendance_with_qr(qr_uuid, marked_by_user_id) do
    GenServer.call(__MODULE__, {:mark_attendance_with_qr, qr_uuid, marked_by_user_id})
  end

  @doc """
  Generates a QR code for a student.
  """
  def generate_qr_code(student_id, course_id) do
    GenServer.call(__MODULE__, {:generate_qr_code, student_id, course_id})
  end

  @doc """
  Gets attendance records for a course on a specific date.
  """
  def get_attendance_for_course(course_id, date \\ Date.utc_today()) do
    GenServer.call(__MODULE__, {:get_attendance_for_course, course_id, date})
  end

  @doc """
  Gets attendance records for a student.
  """
  def get_attendance_for_student(student_id, course_id \\ nil) do
    GenServer.call(__MODULE__, {:get_attendance_for_student, student_id, course_id})
  end

  @doc """
  Gets an attendance record by ID.
  """
  def get_attendance_record(id) do
    GenServer.call(__MODULE__, {:get_attendance_record, id})
  end

  @doc """
  Updates an attendance record.
  """
  def update_attendance_record(id, status, updated_by_user_id) do
    GenServer.call(__MODULE__, {:update_attendance_record, id, status, updated_by_user_id})
  end

  @doc """
  Lists all QR codes for a student.
  """
  def list_qr_codes_for_student(student_id) do
    GenServer.call(__MODULE__, {:list_qr_codes_for_student, student_id})
  end

  @doc """
  Gets QR code by UUID.
  """
  def get_qr_code(uuid) do
    GenServer.call(__MODULE__, {:get_qr_code, uuid})
  end

  # GenServer callbacks

  @impl true
  def handle_call({:mark_attendance, course_id, student_id, status, marked_by_user_id}, _from, state) do
    with course when not is_nil(course) <- Courses.get_course(course_id),
         student when not is_nil(student) <- Accounts.get_user(student_id),
         marker when not is_nil(marker) <- Accounts.get_user(marked_by_user_id),
         true <- can_mark_attendance?(course, marker),
         true <- student.role == :student,
         true <- student_id in course.student_ids do
      
      # Check if attendance already exists for today
      today = Date.utc_today()
      existing_key = "#{course_id}_#{student_id}_#{Date.to_string(today)}"
      
      case Map.get(state.records, existing_key) do
        nil ->
          # Create new attendance record
          record = Record.new(%{
            course_id: course_id,
            student_id: student_id,
            date: today,
            status: status,
            marked_by: marked_by_user_id
          })
          
          case Record.validate(record) do
            {:ok, valid_record} ->
              new_state = put_in(state.records[existing_key], valid_record)
              {:reply, {:ok, valid_record}, new_state}
            
            {:error, errors} ->
              {:reply, {:error, errors}, state}
          end
        
        existing_record ->
          # Update existing record
          updated_record = Record.update_status(existing_record, status, marked_by_user_id)
          new_state = put_in(state.records[existing_key], updated_record)
          {:reply, {:ok, updated_record}, new_state}
      end
    else
      nil -> {:reply, {:error, ["Course, student, or marker not found"]}, state}
      false -> {:reply, {:error, ["Insufficient permissions or invalid student"]}, state}
    end
  end

  @impl true
  def handle_call({:mark_attendance_with_qr, qr_uuid, marked_by_user_id}, _from, state) do
    with qr_code when not is_nil(qr_code) <- Map.get(state.qr_codes, qr_uuid),
         true <- QRCode.valid?(qr_code),
         course when not is_nil(course) <- Courses.get_course(qr_code.course_id),
         marker when not is_nil(marker) <- Accounts.get_user(marked_by_user_id),
         true <- can_mark_attendance?(course, marker) do
      
      # Mark QR code as used
      used_qr_code = QRCode.mark_used(qr_code)
      new_qr_state = put_in(state.qr_codes[qr_uuid], used_qr_code)
      
      # Mark attendance
      today = Date.utc_today()
      existing_key = "#{qr_code.course_id}_#{qr_code.student_id}_#{Date.to_string(today)}"
      
      case Map.get(state.records, existing_key) do
        nil ->
          # Create new attendance record
          record = Record.new(%{
            course_id: qr_code.course_id,
            student_id: qr_code.student_id,
            date: today,
            status: :present,
            marked_by: marked_by_user_id,
            qr_uuid: qr_uuid
          })
          
          case Record.validate(record) do
            {:ok, valid_record} ->
              final_state = put_in(new_qr_state.records[existing_key], valid_record)
              {:reply, {:ok, valid_record}, final_state}
            
            {:error, errors} ->
              {:reply, {:error, errors}, new_qr_state}
          end
        
        existing_record ->
          # Update existing record
          updated_record = Record.mark_with_qr(existing_record, qr_uuid, marked_by_user_id)
          final_state = put_in(new_qr_state.records[existing_key], updated_record)
          {:reply, {:ok, updated_record}, final_state}
      end
    else
      nil -> {:reply, {:error, ["QR code not found"]}, state}
      false -> {:reply, {:error, ["QR code expired, already used, or insufficient permissions"]}, state}
    end
  end

  @impl true
  def handle_call({:generate_qr_code, student_id, course_id}, _from, state) do
    with student when not is_nil(student) <- Accounts.get_user(student_id),
         course when not is_nil(course) <- Courses.get_course(course_id),
         true <- student.role == :student,
         true <- student_id in course.student_ids do
      
      qr_code = QRCode.generate(student_id, course_id)
      new_state = put_in(state.qr_codes[qr_code.uuid], qr_code)
      {:reply, {:ok, qr_code}, new_state}
    else
      nil -> {:reply, {:error, ["Student or course not found"]}, state}
      false -> {:reply, {:error, ["Student not enrolled in course"]}, state}
    end
  end

  @impl true
  def handle_call({:get_attendance_for_course, course_id, date}, _from, state) do
    records = Map.values(state.records)
              |> Enum.filter(fn r -> r.course_id == course_id and Date.compare(r.date, date) == :eq end)
    {:reply, records, state}
  end

  @impl true
  def handle_call({:get_attendance_for_student, student_id, course_id}, _from, state) do
    records = Map.values(state.records)
              |> Enum.filter(fn r -> 
                r.student_id == student_id and (is_nil(course_id) or r.course_id == course_id)
              end)
    {:reply, records, state}
  end

  @impl true
  def handle_call({:get_attendance_record, id}, _from, state) do
    record = Enum.find(Map.values(state.records), fn r -> r.id == id end)
    {:reply, record, state}
  end

  @impl true
  def handle_call({:update_attendance_record, id, status, updated_by_user_id}, _from, state) do
    case Enum.find(state.records, fn {_k, r} -> r.id == id end) do
      nil ->
        {:reply, {:error, ["Attendance record not found"]}, state}
      
      {key, record} ->
        with course when not is_nil(course) <- Courses.get_course(record.course_id),
             marker when not is_nil(marker) <- Accounts.get_user(updated_by_user_id),
             true <- can_mark_attendance?(course, marker) do
          
          updated_record = Record.update_status(record, status, updated_by_user_id)
          new_state = put_in(state.records[key], updated_record)
          {:reply, {:ok, updated_record}, new_state}
        else
          nil -> {:reply, {:error, ["Course or user not found"]}, state}
          false -> {:reply, {:error, ["Insufficient permissions"]}, state}
        end
    end
  end

  @impl true
  def handle_call({:list_qr_codes_for_student, student_id}, _from, state) do
    qr_codes = Map.values(state.qr_codes)
               |> Enum.filter(fn qr -> qr.student_id == student_id end)
    {:reply, qr_codes, state}
  end

  @impl true
  def handle_call({:get_qr_code, uuid}, _from, state) do
    qr_code = Map.get(state.qr_codes, uuid)
    {:reply, qr_code, state}
  end

  defp can_mark_attendance?(course, user) do
    case user.role do
      :admin -> true
      :head_teacher -> course.head_teacher_id == user.id
      :teacher -> user.id in course.teacher_ids
      _ -> false
    end
  end
end