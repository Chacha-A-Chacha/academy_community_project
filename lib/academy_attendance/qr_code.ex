defmodule AcademyAttendance.QRCode do
  @moduledoc """
  QR code generation and management for student attendance.
  Generates UUID-based QR codes that students can use for attendance marking.
  """

  import Bitwise

  defstruct [:uuid, :student_id, :course_id, :generated_at, :expires_at, :used]

  @type t :: %__MODULE__{
    uuid: String.t(),
    student_id: String.t(),
    course_id: String.t(),
    generated_at: DateTime.t(),
    expires_at: DateTime.t(),
    used: boolean()
  }

  @doc """
  Generates a new QR code for a student and course.
  QR codes expire after 1 hour by default.
  """
  def generate(student_id, course_id, opts \\ []) do
    now = DateTime.utc_now()
    expires_in_minutes = Keyword.get(opts, :expires_in_minutes, 60)
    expires_at = DateTime.add(now, expires_in_minutes * 60, :second)

    %__MODULE__{
      uuid: generate_uuid(),
      student_id: student_id,
      course_id: course_id,
      generated_at: now,
      expires_at: expires_at,
      used: false
    }
  end

  @doc """
  Checks if a QR code is valid for use.
  """
  def valid?(%__MODULE__{} = qr_code) do
    not expired?(qr_code) and not qr_code.used
  end

  @doc """
  Marks a QR code as used.
  """
  def mark_used(%__MODULE__{} = qr_code) do
    %{qr_code | used: true}
  end

  @doc """
  Checks if a QR code has expired.
  """
  def expired?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :gt
  end

  @doc """
  Gets the QR code data as a string (what would be encoded in the QR code).
  """
  def to_qr_data(%__MODULE__{} = qr_code) do
    %{
      uuid: qr_code.uuid,
      student_id: qr_code.student_id,
      course_id: qr_code.course_id,
      generated_at: DateTime.to_iso8601(qr_code.generated_at),
      expires_at: DateTime.to_iso8601(qr_code.expires_at)
    }
    |> Jason.encode!()
  rescue
    # Fallback if Jason is not available
    _e ->
      "#{qr_code.uuid}|#{qr_code.student_id}|#{qr_code.course_id}|#{DateTime.to_iso8601(qr_code.generated_at)}|#{DateTime.to_iso8601(qr_code.expires_at)}"
  end

  @doc """
  Parses QR code data from a string.
  """
  def from_qr_data(data) when is_binary(data) do
    try do
      parsed = Jason.decode!(data)
      
      {:ok, %__MODULE__{
        uuid: parsed["uuid"],
        student_id: parsed["student_id"],
        course_id: parsed["course_id"],
        generated_at: DateTime.from_iso8601(parsed["generated_at"]) |> elem(1),
        expires_at: DateTime.from_iso8601(parsed["expires_at"]) |> elem(1),
        used: false
      }}
    rescue
      # Fallback parsing for pipe-separated format
      _e ->
        case String.split(data, "|") do
          [uuid, student_id, course_id, generated_at_str, expires_at_str] ->
            with {:ok, generated_at, _} <- DateTime.from_iso8601(generated_at_str),
                 {:ok, expires_at, _} <- DateTime.from_iso8601(expires_at_str) do
              {:ok, %__MODULE__{
                uuid: uuid,
                student_id: student_id,
                course_id: course_id,
                generated_at: generated_at,
                expires_at: expires_at,
                used: false
              }}
            else
              _ -> {:error, "Invalid QR code format"}
            end
          
          _ -> {:error, "Invalid QR code format"}
        end
    end
  end

  @doc """
  Gets remaining time until expiration in minutes.
  """
  def time_until_expiry(%__MODULE__{expires_at: expires_at}) do
    now = DateTime.utc_now()
    
    case DateTime.compare(expires_at, now) do
      :gt -> DateTime.diff(expires_at, now, :second) |> div(60)
      _ -> 0
    end
  end

  defp generate_uuid do
    # Generate a UUID-like string using crypto random bytes
    <<a::32, b::16, c::16, d::16, e::48>> = :crypto.strong_rand_bytes(16)
    
    # Format as UUID v4
    version = 4
    variant = 2
    
    c = (c &&& 0x0fff) ||| (version <<< 12)
    d = (d &&& 0x3fff) ||| (variant <<< 14)
    
    [
      :io_lib.format("~8.16.0b", [a]),
      :io_lib.format("~4.16.0b", [b]),
      :io_lib.format("~4.16.0b", [c]),
      :io_lib.format("~4.16.0b", [d]),
      :io_lib.format("~12.16.0b", [e])
    ]
    |> Enum.join("-")
    |> to_string()
  end
end