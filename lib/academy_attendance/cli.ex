defmodule AcademyAttendance.CLI do
  @moduledoc """
  Command-line interface for the Academy Attendance System.
  Provides an interactive way to test all the system functionality.
  """

  alias AcademyAttendance.{Accounts, Courses, Attendance, QRCode}

  def start do
    IO.puts("\n=== Academy Attendance System ===")
    IO.puts("Welcome to the Weekend Academy Student Attendance Tracking System")
    IO.puts("Using Student ID or QR codes with UUID data")
    IO.puts("=====================================\n")
    
    main_menu()
  end

  defp main_menu do
    IO.puts("Main Menu:")
    IO.puts("1. User Management")
    IO.puts("2. Course Management") 
    IO.puts("3. Attendance Management")
    IO.puts("4. QR Code Management")
    IO.puts("5. Demo System")
    IO.puts("6. Exit")
    
    choice = get_input("Select an option (1-6): ")
    
    case choice do
      "1" -> user_menu()
      "2" -> course_menu()
      "3" -> attendance_menu()
      "4" -> qr_menu()
      "5" -> demo_system()
      "6" -> IO.puts("Goodbye!")
      _ -> 
        IO.puts("Invalid option. Please try again.")
        main_menu()
    end
  end

  defp user_menu do
    IO.puts("\n=== User Management ===")
    IO.puts("1. Create Admin + Head Teacher")
    IO.puts("2. Create User")
    IO.puts("3. List Users")
    IO.puts("4. List Users by Role")
    IO.puts("5. Get User by Email")
    IO.puts("6. Back to Main Menu")
    
    choice = get_input("Select an option (1-6): ")
    
    case choice do
      "1" -> create_admin_and_head_teacher()
      "2" -> create_user()
      "3" -> list_users()
      "4" -> list_users_by_role()
      "5" -> get_user_by_email()
      "6" -> main_menu()
      _ -> 
        IO.puts("Invalid option. Please try again.")
        user_menu()
    end
  end

  defp course_menu do
    IO.puts("\n=== Course Management ===")
    IO.puts("1. Create Course")
    IO.puts("2. List All Courses")
    IO.puts("3. Add Teacher to Course")
    IO.puts("4. Add Student to Course")
    IO.puts("5. View Course Details")
    IO.puts("6. Back to Main Menu")
    
    choice = get_input("Select an option (1-6): ")
    
    case choice do
      "1" -> create_course()
      "2" -> list_courses()
      "3" -> add_teacher_to_course()
      "4" -> add_student_to_course()
      "5" -> view_course_details()
      "6" -> main_menu()
      _ -> 
        IO.puts("Invalid option. Please try again.")
        course_menu()
    end
  end

  defp attendance_menu do
    IO.puts("\n=== Attendance Management ===")
    IO.puts("1. Mark Attendance")
    IO.puts("2. Mark Attendance with QR Code")
    IO.puts("3. View Course Attendance")
    IO.puts("4. View Student Attendance")
    IO.puts("5. Back to Main Menu")
    
    choice = get_input("Select an option (1-5): ")
    
    case choice do
      "1" -> mark_attendance()
      "2" -> mark_attendance_with_qr()
      "3" -> view_course_attendance()
      "4" -> view_student_attendance()
      "5" -> main_menu()
      _ -> 
        IO.puts("Invalid option. Please try again.")
        attendance_menu()
    end
  end

  defp qr_menu do
    IO.puts("\n=== QR Code Management ===")
    IO.puts("1. Generate QR Code")
    IO.puts("2. List Student QR Codes")
    IO.puts("3. View QR Code Details")
    IO.puts("4. Back to Main Menu")
    
    choice = get_input("Select an option (1-4): ")
    
    case choice do
      "1" -> generate_qr_code()
      "2" -> list_qr_codes()
      "3" -> view_qr_code()
      "4" -> main_menu()
      _ -> 
        IO.puts("Invalid option. Please try again.")
        qr_menu()
    end
  end

  # User Management Functions

  defp create_admin_and_head_teacher do
    IO.puts("\n=== Create Admin + Head Teacher ===")
    
    admin_name = get_input("Admin Name: ")
    admin_email = get_input("Admin Email: ")
    
    ht_name = get_input("Head Teacher Name: ")
    ht_email = get_input("Head Teacher Email: ")
    
    admin_attrs = %{name: admin_name, email: admin_email}
    ht_attrs = %{name: ht_name, email: ht_email}
    
    case Accounts.create_admin_and_head_teacher(admin_attrs, ht_attrs) do
      {:ok, {admin, head_teacher}} ->
        IO.puts("✅ Successfully created:")
        IO.puts("   Admin: #{admin.name} (#{admin.email}) - ID: #{admin.id}")
        IO.puts("   Head Teacher: #{head_teacher.name} (#{head_teacher.email}) - ID: #{head_teacher.id}")
      
      {:error, errors} ->
        IO.puts("❌ Error creating users:")
        Enum.each(errors, fn error -> IO.puts("   - #{error}") end)
    end
    
    user_menu()
  end

  defp create_user do
    IO.puts("\n=== Create User ===")
    
    name = get_input("Name: ")
    email = get_input("Email: ")
    role = get_input("Role (admin/head_teacher/teacher/student): ")
    
    role_atom = case role do
      "admin" -> :admin
      "head_teacher" -> :head_teacher
      "teacher" -> :teacher
      "student" -> :student
      _ -> :student
    end
    
    attrs = %{name: name, email: email, role: role_atom}
    
    attrs = if role_atom == :student do
      student_id = get_input("Student ID: ")
      Map.put(attrs, :student_id, student_id)
    else
      attrs
    end
    
    case Accounts.create_user(attrs) do
      {:ok, user} ->
        IO.puts("✅ User created successfully:")
        IO.puts("   #{user.name} (#{user.email}) - Role: #{user.role} - ID: #{user.id}")
        if user.student_id, do: IO.puts("   Student ID: #{user.student_id}")
      
      {:error, errors} ->
        IO.puts("❌ Error creating user:")
        Enum.each(errors, fn error -> IO.puts("   - #{error}") end)
    end
    
    user_menu()
  end

  defp list_users do
    IO.puts("\n=== All Users ===")
    users = Accounts.list_users()
    
    if Enum.empty?(users) do
      IO.puts("No users found.")
    else
      Enum.each(users, fn user ->
        student_info = if user.student_id, do: " (Student ID: #{user.student_id})", else: ""
        IO.puts("#{user.name} - #{user.email} - #{user.role}#{student_info} - ID: #{user.id}")
      end)
    end
    
    user_menu()
  end

  defp list_users_by_role do
    role = get_input("Role (admin/head_teacher/teacher/student): ")
    
    role_atom = case role do
      "admin" -> :admin
      "head_teacher" -> :head_teacher
      "teacher" -> :teacher
      "student" -> :student
      _ -> nil
    end
    
    if role_atom do
      IO.puts("\n=== #{String.capitalize(role)} Users ===")
      users = Accounts.list_users_by_role(role_atom)
      
      if Enum.empty?(users) do
        IO.puts("No #{role} users found.")
      else
        Enum.each(users, fn user ->
          student_info = if user.student_id, do: " (Student ID: #{user.student_id})", else: ""
          IO.puts("#{user.name} - #{user.email}#{student_info} - ID: #{user.id}")
        end)
      end
    else
      IO.puts("Invalid role.")
    end
    
    user_menu()
  end

  defp get_user_by_email do
    email = get_input("Email: ")
    
    case Accounts.get_user_by_email(email) do
      nil ->
        IO.puts("User not found.")
      
      user ->
        IO.puts("\n=== User Details ===")
        IO.puts("Name: #{user.name}")
        IO.puts("Email: #{user.email}")
        IO.puts("Role: #{user.role}")
        if user.student_id, do: IO.puts("Student ID: #{user.student_id}")
        IO.puts("ID: #{user.id}")
    end
    
    user_menu()
  end

  # Course Management Functions

  defp create_course do
    IO.puts("\n=== Create Course ===")
    
    name = get_input("Course Name: ")
    description = get_input("Course Description: ")
    head_teacher_email = get_input("Head Teacher Email: ")
    admin_email = get_input("Admin Email (who is creating this): ")
    
    case {Accounts.get_user_by_email(head_teacher_email), Accounts.get_user_by_email(admin_email)} do
      {nil, _} ->
        IO.puts("❌ Head teacher not found.")
      
      {_, nil} ->
        IO.puts("❌ Admin not found.")
      
      {head_teacher, admin} ->
        if head_teacher.role != :head_teacher do
          IO.puts("❌ User is not a head teacher.")
        else
          attrs = %{
            name: name,
            description: description,
            head_teacher_id: head_teacher.id
          }
          
          case Courses.create_course(attrs, admin.id) do
            {:ok, course} ->
              IO.puts("✅ Course created successfully:")
              IO.puts("   #{course.name} - #{course.description}")
              IO.puts("   Head Teacher: #{head_teacher.name}")
              IO.puts("   Course ID: #{course.id}")
            
            {:error, errors} ->
              IO.puts("❌ Error creating course:")
              Enum.each(errors, fn error -> IO.puts("   - #{error}") end)
          end
        end
    end
    
    course_menu()
  end

  defp list_courses do
    IO.puts("\n=== All Courses ===")
    courses = Courses.list_courses()
    
    if Enum.empty?(courses) do
      IO.puts("No courses found.")
    else
      Enum.each(courses, fn course ->
        head_teacher = Accounts.get_user(course.head_teacher_id)
        IO.puts("#{course.name} - #{course.description}")
        IO.puts("  Head Teacher: #{head_teacher.name}")
        IO.puts("  Teachers: #{length(course.teacher_ids)}, Students: #{length(course.student_ids)}")
        IO.puts("  Course ID: #{course.id}")
        IO.puts("")
      end)
    end
    
    course_menu()
  end

  defp add_teacher_to_course do
    IO.puts("\n=== Add Teacher to Course ===")
    
    list_courses()
    course_id = get_input("Course ID: ")
    teacher_email = get_input("Teacher Email: ")
    added_by_email = get_input("Added by (Head Teacher/Admin) Email: ")
    
    case {Courses.get_course(course_id), Accounts.get_user_by_email(teacher_email), Accounts.get_user_by_email(added_by_email)} do
      {nil, _, _} ->
        IO.puts("❌ Course not found.")
      
      {_, nil, _} ->
        IO.puts("❌ Teacher not found.")
      
      {_, _, nil} ->
        IO.puts("❌ User adding teacher not found.")
      
      {course, teacher, added_by} ->
        case Courses.add_teacher_to_course(course_id, teacher.id, added_by.id) do
          {:ok, updated_course} ->
            IO.puts("✅ Teacher added successfully to course.")
            IO.puts("   Course now has #{length(updated_course.teacher_ids)} teachers.")
          
          {:error, errors} ->
            IO.puts("❌ Error adding teacher:")
            Enum.each(errors, fn error -> IO.puts("   - #{error}") end)
        end
    end
    
    course_menu()
  end

  defp add_student_to_course do
    IO.puts("\n=== Add Student to Course ===")
    
    list_courses()
    course_id = get_input("Course ID: ")
    student_email = get_input("Student Email: ")
    added_by_email = get_input("Added by (Head Teacher/Admin) Email: ")
    
    case {Courses.get_course(course_id), Accounts.get_user_by_email(student_email), Accounts.get_user_by_email(added_by_email)} do
      {nil, _, _} ->
        IO.puts("❌ Course not found.")
      
      {_, nil, _} ->
        IO.puts("❌ Student not found.")
      
      {_, _, nil} ->
        IO.puts("❌ User adding student not found.")
      
      {course, student, added_by} ->
        case Courses.add_student_to_course(course_id, student.id, added_by.id) do
          {:ok, updated_course} ->
            IO.puts("✅ Student added successfully to course.")
            IO.puts("   Course now has #{length(updated_course.student_ids)} students.")
          
          {:error, errors} ->
            IO.puts("❌ Error adding student:")
            Enum.each(errors, fn error -> IO.puts("   - #{error}") end)
        end
    end
    
    course_menu()
  end

  defp view_course_details do
    list_courses()
    course_id = get_input("Course ID: ")
    
    case Courses.get_course(course_id) do
      nil ->
        IO.puts("❌ Course not found.")
      
      course ->
        head_teacher = Accounts.get_user(course.head_teacher_id)
        
        IO.puts("\n=== Course Details ===")
        IO.puts("Name: #{course.name}")
        IO.puts("Description: #{course.description}")
        IO.puts("Head Teacher: #{head_teacher.name} (#{head_teacher.email})")
        
        IO.puts("\nTeachers:")
        if Enum.empty?(course.teacher_ids) do
          IO.puts("  No teachers assigned.")
        else
          Enum.each(course.teacher_ids, fn teacher_id ->
            teacher = Accounts.get_user(teacher_id)
            IO.puts("  - #{teacher.name} (#{teacher.email})")
          end)
        end
        
        IO.puts("\nStudents:")
        if Enum.empty?(course.student_ids) do
          IO.puts("  No students enrolled.")
        else
          Enum.each(course.student_ids, fn student_id ->
            student = Accounts.get_user(student_id)
            IO.puts("  - #{student.name} (#{student.email}) - Student ID: #{student.student_id}")
          end)
        end
    end
    
    course_menu()
  end

  # Attendance Management Functions

  defp mark_attendance do
    IO.puts("\n=== Mark Attendance ===")
    
    list_courses()
    course_id = get_input("Course ID: ")
    student_email = get_input("Student Email: ")
    status = get_input("Status (present/absent/late): ")
    marked_by_email = get_input("Marked by Email: ")
    
    status_atom = case status do
      "present" -> :present
      "absent" -> :absent
      "late" -> :late
      _ -> :absent
    end
    
    case {Accounts.get_user_by_email(student_email), Accounts.get_user_by_email(marked_by_email)} do
      {nil, _} ->
        IO.puts("❌ Student not found.")
      
      {_, nil} ->
        IO.puts("❌ User marking attendance not found.")
      
      {student, marker} ->
        case Attendance.mark_attendance(course_id, student.id, status_atom, marker.id) do
          {:ok, record} ->
            IO.puts("✅ Attendance marked successfully:")
            IO.puts("   Student: #{student.name}")
            IO.puts("   Status: #{record.status}")
            IO.puts("   Date: #{record.date}")
            IO.puts("   Marked by: #{marker.name}")
          
          {:error, errors} ->
            IO.puts("❌ Error marking attendance:")
            Enum.each(errors, fn error -> IO.puts("   - #{error}") end)
        end
    end
    
    attendance_menu()
  end

  defp mark_attendance_with_qr do
    IO.puts("\n=== Mark Attendance with QR Code ===")
    
    qr_uuid = get_input("QR Code UUID: ")
    marked_by_email = get_input("Marked by Email: ")
    
    case Accounts.get_user_by_email(marked_by_email) do
      nil ->
        IO.puts("❌ User marking attendance not found.")
      
      marker ->
        case Attendance.mark_attendance_with_qr(qr_uuid, marker.id) do
          {:ok, record} ->
            student = Accounts.get_user(record.student_id)
            course = Courses.get_course(record.course_id)
            
            IO.puts("✅ Attendance marked with QR code:")
            IO.puts("   Student: #{student.name}")
            IO.puts("   Course: #{course.name}")
            IO.puts("   Status: #{record.status}")
            IO.puts("   Date: #{record.date}")
            IO.puts("   Marked by: #{marker.name}")
            IO.puts("   QR UUID: #{record.qr_uuid}")
          
          {:error, errors} ->
            IO.puts("❌ Error marking attendance:")
            Enum.each(errors, fn error -> IO.puts("   - #{error}") end)
        end
    end
    
    attendance_menu()
  end

  defp view_course_attendance do
    IO.puts("\n=== View Course Attendance ===")
    
    list_courses()
    course_id = get_input("Course ID: ")
    date_str = get_input("Date (YYYY-MM-DD, or press Enter for today): ")
    
    date = if String.trim(date_str) == "" do
      Date.utc_today()
    else
      case Date.from_iso8601(date_str) do
        {:ok, date} -> date
        _ -> Date.utc_today()
      end
    end
    
    case Courses.get_course(course_id) do
      nil ->
        IO.puts("❌ Course not found.")
      
      course ->
        records = Attendance.get_attendance_for_course(course_id, date)
        
        IO.puts("\n=== Attendance for #{course.name} on #{date} ===")
        
        if Enum.empty?(records) do
          IO.puts("No attendance records found for this date.")
        else
          Enum.each(records, fn record ->
            student = Accounts.get_user(record.student_id)
            marker = Accounts.get_user(record.marked_by)
            
            IO.puts("#{student.name} (#{student.student_id}) - #{record.status}")
            IO.puts("  Marked by: #{marker.name}")
            if record.qr_uuid, do: IO.puts("  QR Code Used: #{record.qr_uuid}")
            IO.puts("")
          end)
        end
    end
    
    attendance_menu()
  end

  defp view_student_attendance do
    IO.puts("\n=== View Student Attendance ===")
    
    student_email = get_input("Student Email: ")
    
    case Accounts.get_user_by_email(student_email) do
      nil ->
        IO.puts("❌ Student not found.")
      
      student ->
        records = Attendance.get_attendance_for_student(student.id)
        
        IO.puts("\n=== Attendance for #{student.name} ===")
        
        if Enum.empty?(records) do
          IO.puts("No attendance records found.")
        else
          Enum.each(records, fn record ->
            course = Courses.get_course(record.course_id)
            marker = Accounts.get_user(record.marked_by)
            
            IO.puts("#{course.name} - #{record.date} - #{record.status}")
            IO.puts("  Marked by: #{marker.name}")
            if record.qr_uuid, do: IO.puts("  QR Code Used: #{record.qr_uuid}")
            IO.puts("")
          end)
        end
    end
    
    attendance_menu()
  end

  # QR Code Management Functions

  defp generate_qr_code do
    IO.puts("\n=== Generate QR Code ===")
    
    student_email = get_input("Student Email: ")
    
    case Accounts.get_user_by_email(student_email) do
      nil ->
        IO.puts("❌ Student not found.")
      
      student ->
        # List courses the student is enrolled in
        all_courses = Courses.list_courses()
        student_courses = Enum.filter(all_courses, fn course -> 
          student.id in course.student_ids 
        end)
        
        if Enum.empty?(student_courses) do
          IO.puts("❌ Student is not enrolled in any courses.")
        else
          IO.puts("\nCourses student is enrolled in:")
          Enum.with_index(student_courses, 1)
          |> Enum.each(fn {course, index} ->
            IO.puts("#{index}. #{course.name} (ID: #{course.id})")
          end)
          
          course_choice = get_input("Select course (number): ")
          
          case Integer.parse(course_choice) do
            {index, _} when index > 0 and index <= length(student_courses) ->
              course = Enum.at(student_courses, index - 1)
              
              case Attendance.generate_qr_code(student.id, course.id) do
                {:ok, qr_code} ->
                  IO.puts("✅ QR Code generated successfully:")
                  IO.puts("   UUID: #{qr_code.uuid}")
                  IO.puts("   Student: #{student.name}")
                  IO.puts("   Course: #{course.name}")
                  IO.puts("   Generated: #{qr_code.generated_at}")
                  IO.puts("   Expires: #{qr_code.expires_at}")
                  IO.puts("   Time until expiry: #{QRCode.time_until_expiry(qr_code)} minutes")
                  IO.puts("\n   QR Code Data:")
                  IO.puts("   #{QRCode.to_qr_data(qr_code)}")
                
                {:error, errors} ->
                  IO.puts("❌ Error generating QR code:")
                  Enum.each(errors, fn error -> IO.puts("   - #{error}") end)
              end
            
            _ ->
              IO.puts("❌ Invalid course selection.")
          end
        end
    end
    
    qr_menu()
  end

  defp list_qr_codes do
    IO.puts("\n=== List QR Codes ===")
    
    student_email = get_input("Student Email: ")
    
    case Accounts.get_user_by_email(student_email) do
      nil ->
        IO.puts("❌ Student not found.")
      
      student ->
        qr_codes = Attendance.list_qr_codes_for_student(student.id)
        
        if Enum.empty?(qr_codes) do
          IO.puts("No QR codes found for this student.")
        else
          IO.puts("\n=== QR Codes for #{student.name} ===")
          
          Enum.each(qr_codes, fn qr_code ->
            course = Courses.get_course(qr_code.course_id)
            status = cond do
              qr_code.used -> "Used"
              QRCode.expired?(qr_code) -> "Expired"
              true -> "Valid (#{QRCode.time_until_expiry(qr_code)} min left)"
            end
            
            IO.puts("UUID: #{qr_code.uuid}")
            IO.puts("  Course: #{course.name}")
            IO.puts("  Generated: #{qr_code.generated_at}")
            IO.puts("  Status: #{status}")
            IO.puts("")
          end)
        end
    end
    
    qr_menu()
  end

  defp view_qr_code do
    IO.puts("\n=== View QR Code Details ===")
    
    uuid = get_input("QR Code UUID: ")
    
    case Attendance.get_qr_code(uuid) do
      nil ->
        IO.puts("❌ QR code not found.")
      
      qr_code ->
        student = Accounts.get_user(qr_code.student_id)
        course = Courses.get_course(qr_code.course_id)
        
        IO.puts("\n=== QR Code Details ===")
        IO.puts("UUID: #{qr_code.uuid}")
        IO.puts("Student: #{student.name} (#{student.email})")
        IO.puts("Course: #{course.name}")
        IO.puts("Generated: #{qr_code.generated_at}")
        IO.puts("Expires: #{qr_code.expires_at}")
        IO.puts("Used: #{qr_code.used}")
        IO.puts("Valid: #{QRCode.valid?(qr_code)}")
        IO.puts("Time until expiry: #{QRCode.time_until_expiry(qr_code)} minutes")
        
        IO.puts("\nQR Code Data:")
        IO.puts(QRCode.to_qr_data(qr_code))
    end
    
    qr_menu()
  end

  # Demo System

  defp demo_system do
    IO.puts("\n=== Demo System ===")
    IO.puts("This will create sample data to demonstrate the system...")
    
    # Create users
    IO.puts("\n1. Creating sample users...")
    
    {:ok, {admin, head_teacher}} = Accounts.create_admin_and_head_teacher(
      %{name: "Admin User", email: "admin@academy.com"},
      %{name: "Head Teacher Smith", email: "head.teacher@academy.com"}
    )
    
    {:ok, teacher1} = Accounts.create_user(%{
      name: "Teacher Johnson", 
      email: "teacher1@academy.com", 
      role: :teacher
    })
    
    {:ok, teacher2} = Accounts.create_user(%{
      name: "Teacher Williams", 
      email: "teacher2@academy.com", 
      role: :teacher
    })
    
    {:ok, student1} = Accounts.create_user(%{
      name: "Alice Johnson", 
      email: "alice@student.com", 
      role: :student, 
      student_id: "STU001"
    })
    
    {:ok, student2} = Accounts.create_user(%{
      name: "Bob Smith", 
      email: "bob@student.com", 
      role: :student, 
      student_id: "STU002"
    })
    
    {:ok, student3} = Accounts.create_user(%{
      name: "Carol Davis", 
      email: "carol@student.com", 
      role: :student, 
      student_id: "STU003"
    })
    
    IO.puts("   ✅ Created admin, head teacher, 2 teachers, and 3 students")
    
    # Create courses
    IO.puts("\n2. Creating sample courses...")
    
    {:ok, course1} = Courses.create_course(%{
      name: "Web Development Fundamentals",
      description: "Learn HTML, CSS, and JavaScript basics",
      head_teacher_id: head_teacher.id
    }, admin.id)
    
    {:ok, course2} = Courses.create_course(%{
      name: "Data Structures & Algorithms",
      description: "Learn fundamental CS concepts",
      head_teacher_id: head_teacher.id
    }, admin.id)
    
    IO.puts("   ✅ Created 2 courses")
    
    # Add teachers and students to courses
    IO.puts("\n3. Enrolling teachers and students...")
    
    Courses.add_teacher_to_course(course1.id, teacher1.id, head_teacher.id)
    Courses.add_teacher_to_course(course2.id, teacher2.id, head_teacher.id)
    
    Courses.add_student_to_course(course1.id, student1.id, head_teacher.id)
    Courses.add_student_to_course(course1.id, student2.id, head_teacher.id)
    Courses.add_student_to_course(course2.id, student2.id, head_teacher.id)
    Courses.add_student_to_course(course2.id, student3.id, head_teacher.id)
    
    IO.puts("   ✅ Enrolled teachers and students in courses")
    
    # Generate QR codes
    IO.puts("\n4. Generating QR codes...")
    
    {:ok, qr1} = Attendance.generate_qr_code(student1.id, course1.id)
    {:ok, qr2} = Attendance.generate_qr_code(student2.id, course1.id)
    
    IO.puts("   ✅ Generated QR codes for students")
    
    # Mark some attendance
    IO.puts("\n5. Marking sample attendance...")
    
    Attendance.mark_attendance(course1.id, student1.id, :present, teacher1.id)
    Attendance.mark_attendance_with_qr(qr2.uuid, teacher1.id)
    Attendance.mark_attendance(course2.id, student2.id, :late, teacher2.id)
    Attendance.mark_attendance(course2.id, student3.id, :absent, teacher2.id)
    
    IO.puts("   ✅ Marked attendance for various students")
    
    IO.puts("\n🎉 Demo data created successfully!")
    IO.puts("\nSample data summary:")
    IO.puts("• Admin: admin@academy.com")
    IO.puts("• Head Teacher: head.teacher@academy.com") 
    IO.puts("• Teachers: teacher1@academy.com, teacher2@academy.com")
    IO.puts("• Students: alice@student.com (STU001), bob@student.com (STU002), carol@student.com (STU003)")
    IO.puts("• Courses: Web Development Fundamentals, Data Structures & Algorithms")
    IO.puts("• Sample attendance records and QR codes created")
    
    IO.puts("\nYou can now explore the system using the menus!")
    
    main_menu()
  end

  defp get_input(prompt) do
    IO.gets(prompt) |> String.trim()
  end
end