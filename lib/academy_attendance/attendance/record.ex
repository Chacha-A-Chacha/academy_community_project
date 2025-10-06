defmodule AcademyAttendance.Attendance.Record do
  @moduledoc """
  Attendance record schema for tracking student attendance.
  Supports both Student ID and QR code-based attendance marking.
  """

  defstruct [:id, :course_id, :student_id, :date, :status, :marked_by, :qr_uuid, :inserted_at, :updated_at]

  @type status :: :present | :absent | :late

  @type t :: %__MODULE__{
    id: String.t(),
    course_id: String.t(),
    student_id: String.t(),
    date: Date.t(),
    status: status(),
    marked_by: String.t(),
    qr_uuid: String.t() | nil,
    inserted_at: DateTime.t(),
    updated_at: DateTime.t()
  }

  @statuses [:present, :absent, :late]

  def valid_statuses, do: @statuses

  @doc """
  Creates a new attendance record with the given attributes.
  """
  def new(attrs \\ %{}) do
    now = DateTime.utc_now()
    
    %__MODULE__{
      id: generate_id(),
      course_id: Map.get(attrs, :course_id),
      student_id: Map.get(attrs, :student_id),
      date: Map.get(attrs, :date, Date.utc_today()),
      status: Map.get(attrs, :status, :absent),
      marked_by: Map.get(attrs, :marked_by),
      qr_uuid: Map.get(attrs, :qr_uuid),
      inserted_at: now,
      updated_at: now
    }
  end

  @doc """
  Validates attendance record data.
  """
  def validate(%__MODULE__{} = record) do
    errors = []
    
    errors = if is_nil(record.course_id), do: ["Course ID is required" | errors], else: errors
    errors = if is_nil(record.student_id), do: ["Student ID is required" | errors], else: errors
    errors = if is_nil(record.date), do: ["Date is required" | errors], else: errors
    errors = if record.status not in @statuses, do: ["Invalid status" | errors], else: errors
    errors = if is_nil(record.marked_by), do: ["Marked by is required" | errors], else: errors
    
    case errors do
      [] -> {:ok, record}
      _ -> {:error, errors}
    end
  end

  @doc """
  Updates attendance record status.
  """
  def update_status(%__MODULE__{} = record, status, marked_by) when status in @statuses do
    %{record |
      status: status,
      marked_by: marked_by,
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Marks attendance using QR code UUID.
  """
  def mark_with_qr(%__MODULE__{} = record, qr_uuid, marked_by) do
    %{record |
      status: :present,
      qr_uuid: qr_uuid,
      marked_by: marked_by,
      updated_at: DateTime.utc_now()
    }
  end

  @doc """
  Checks if the attendance record is for today.
  """
  def for_today?(%__MODULE__{date: date}) do
    Date.compare(date, Date.utc_today()) == :eq
  end

  @doc """
  Gets a display-friendly status string.
  """
  def status_display(%__MODULE__{status: status}) do
    case status do
      :present -> "Present"
      :absent -> "Absent"
      :late -> "Late"
    end
  end

  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.encode64() |> String.replace(~r/[^A-Za-z0-9]/, "")
  end
end