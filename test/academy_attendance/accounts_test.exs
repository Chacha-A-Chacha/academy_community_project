defmodule AcademyAttendance.AccountsTest do
  use ExUnit.Case
  
  alias AcademyAttendance.Accounts
  alias AcademyAttendance.Accounts.User

  setup do
    # Clean up any existing test data before each test
    users = Accounts.list_users()
    Enum.each(users, fn user -> 
      if String.contains?(user.email, ["@example.com", "@academy.com", "@student.com"]) do
        Accounts.delete_user(user.id)
      end
    end)
    :ok
  end

  describe "create_user/1" do
    test "creates a valid user" do
      attrs = %{
        name: "John Doe",
        email: "john@example.com",
        role: :teacher
      }

      assert {:ok, user} = Accounts.create_user(attrs)
      assert user.name == "John Doe"
      assert user.email == "john@example.com"
      assert user.role == :teacher
      assert is_binary(user.id)
    end

    test "creates a student with student_id" do
      attrs = %{
        name: "Jane Student",
        email: "jane@student.com",
        role: :student,
        student_id: "STU001"
      }

      assert {:ok, user} = Accounts.create_user(attrs)
      assert user.student_id == "STU001"
    end

    test "returns error for invalid user" do
      attrs = %{name: "", email: "", role: :invalid}

      assert {:error, errors} = Accounts.create_user(attrs)
      assert "Name is required" in errors
      assert "Email is required" in errors
      assert "Invalid role" in errors
    end
  end

  describe "create_admin_and_head_teacher/2" do
    test "creates both admin and head teacher simultaneously" do
      admin_attrs = %{name: "Admin User", email: "admin@academy.com"}
      ht_attrs = %{name: "Head Teacher", email: "head@academy.com"}

      assert {:ok, {admin, head_teacher}} = 
        Accounts.create_admin_and_head_teacher(admin_attrs, ht_attrs)

      assert admin.role == :admin
      assert head_teacher.role == :head_teacher
      assert admin.name == "Admin User"
      assert head_teacher.name == "Head Teacher"
    end
  end

  describe "user permissions" do
    test "admin has all permissions" do
      user = User.new(%{role: :admin})
      assert User.has_permission?(user, :any_action)
    end

    test "head teacher has course management permissions" do
      user = User.new(%{role: :head_teacher})
      assert User.has_permission?(user, :create_course)
      assert User.has_permission?(user, :manage_course)
      assert User.has_permission?(user, :add_teacher)
      refute User.has_permission?(user, :invalid_action)
    end

    test "student has limited permissions" do
      user = User.new(%{role: :student})
      assert User.has_permission?(user, :generate_qr)
      assert User.has_permission?(user, :view_own_attendance)
      refute User.has_permission?(user, :manage_course)
    end
  end
end