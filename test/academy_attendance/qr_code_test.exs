defmodule AcademyAttendance.QRCodeTest do
  use ExUnit.Case
  
  alias AcademyAttendance.QRCode

  describe "generate/2" do
    test "generates a valid QR code" do
      qr_code = QRCode.generate("student123", "course456")
      
      assert is_binary(qr_code.uuid)
      assert qr_code.student_id == "student123"
      assert qr_code.course_id == "course456"
      assert qr_code.used == false
      assert %DateTime{} = qr_code.generated_at
      assert %DateTime{} = qr_code.expires_at
    end

    test "generates QR code with custom expiration" do
      qr_code = QRCode.generate("student123", "course456", expires_in_minutes: 30)
      
      # Check that expiration is approximately 30 minutes from now
      time_diff = DateTime.diff(qr_code.expires_at, qr_code.generated_at, :second)
      assert time_diff == 30 * 60
    end
  end

  describe "valid?/1" do
    test "returns true for fresh QR code" do
      qr_code = QRCode.generate("student123", "course456")
      assert QRCode.valid?(qr_code)
    end

    test "returns false for used QR code" do
      qr_code = QRCode.generate("student123", "course456")
      used_qr_code = QRCode.mark_used(qr_code)
      refute QRCode.valid?(used_qr_code)
    end

    test "returns false for expired QR code" do
      past_time = DateTime.add(DateTime.utc_now(), -3600, :second) # 1 hour ago
      qr_code = %QRCode{
        uuid: "test-uuid",
        student_id: "student123",
        course_id: "course456",
        generated_at: past_time,
        expires_at: DateTime.add(past_time, 1800, :second), # 30 min later (still in past)
        used: false
      }
      
      refute QRCode.valid?(qr_code)
    end
  end

  describe "to_qr_data/1 and from_qr_data/1" do
    test "converts QR code to data string and back" do
      original_qr_code = QRCode.generate("student123", "course456")
      qr_data = QRCode.to_qr_data(original_qr_code)
      
      assert is_binary(qr_data)
      
      {:ok, parsed_qr_code} = QRCode.from_qr_data(qr_data)
      
      assert parsed_qr_code.uuid == original_qr_code.uuid
      assert parsed_qr_code.student_id == original_qr_code.student_id
      assert parsed_qr_code.course_id == original_qr_code.course_id
    end
  end

  describe "time_until_expiry/1" do
    test "returns correct minutes until expiry" do
      qr_code = QRCode.generate("student123", "course456", expires_in_minutes: 60)
      time_left = QRCode.time_until_expiry(qr_code)
      
      # Should be approximately 60 minutes (allowing for small timing differences)
      assert time_left >= 59 and time_left <= 60
    end

    test "returns 0 for expired QR code" do
      past_time = DateTime.add(DateTime.utc_now(), -3600, :second)
      qr_code = %QRCode{
        uuid: "test-uuid",
        student_id: "student123", 
        course_id: "course456",
        generated_at: past_time,
        expires_at: DateTime.add(past_time, 1800, :second),
        used: false
      }
      
      assert QRCode.time_until_expiry(qr_code) == 0
    end
  end
end