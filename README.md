# Academy Community Project - Student Attendance System

Weekend academy student attendance tracking system using Student ID or QR codes with UUID data. Supports multi-teacher course management with role-based access control.

## Features

### User Roles & Permissions

#### Admin
- Create Course + Head Teacher (simultaneous operation)
- Full system access

#### Head Teacher
- Full course management rights
- Add/remove teachers and students from their courses
- View and manage attendance for their courses

#### Teachers (Added by Head Teacher)
- Mark attendance for students in their assigned courses
- View attendance records for their courses

#### Students
- Generate QR codes on-demand for attendance marking
- View their own attendance status

## System Architecture

The system is built using Elixir with the following core components:

### Contexts
- **Accounts**: User management with role-based access control
- **Courses**: Course management and enrollment
- **Attendance**: Attendance tracking with QR code support

### Key Features
- **UUID-based QR Codes**: Students can generate secure QR codes for attendance
- **Role-based Permissions**: Each user role has specific permissions
- **In-memory Storage**: Currently uses GenServer-based storage (easily replaceable with database)
- **Comprehensive CLI**: Interactive command-line interface for testing and demonstration

## Installation & Setup

### Prerequisites
- Elixir 1.14+
- Erlang/OTP 25+

### Running the System

1. Clone the repository:
```bash
git clone <repository-url>
cd academy_community_project
```

2. Install dependencies (when network access is available):
```bash
mix deps.get
```

3. Compile the application:
```bash
mix compile
```

4. Run tests:
```bash
mix test
```

5. Start the interactive system:
```bash
iex -S mix
```

6. Launch the CLI interface:
```elixir
AcademyAttendance.CLI.start()
```

## Usage

### Quick Start with Demo Data

The system includes a demo mode that creates sample data:

1. Start the CLI interface
2. Select option "5. Demo System"
3. This will create:
   - Admin and Head Teacher accounts
   - Sample teachers and students
   - Courses with enrollments
   - Sample attendance records and QR codes

### User Management

- **Create Admin + Head Teacher**: Simultaneous creation as per requirements
- **Create Users**: Add teachers and students with appropriate roles
- **Role-based Access**: Each role has specific permissions

### Course Management

- **Create Courses**: Admins can create courses with assigned head teachers
- **Manage Enrollment**: Head teachers can add/remove teachers and students
- **Course Access Control**: Role-based access to course management

### Attendance Tracking

- **Manual Attendance**: Teachers can mark attendance by student ID
- **QR Code Attendance**: Students generate QR codes for attendance marking
- **Attendance Reports**: View attendance by course or student
- **Time-based QR Codes**: QR codes expire after 1 hour for security

### QR Code System

- **On-demand Generation**: Students can generate QR codes when needed
- **UUID-based Security**: Each QR code contains a unique UUID
- **Expiration**: QR codes automatically expire to prevent misuse
- **One-time Use**: QR codes can only be used once

## System Design

### Role-based Access Control

The system implements strict role-based permissions:

```elixir
# Example permission checks
User.has_permission?(admin_user, :any_action)           # true
User.has_permission?(head_teacher, :manage_course)      # true
User.has_permission?(teacher, :mark_attendance)         # true
User.has_permission?(student, :generate_qr)             # true
```

### QR Code Security

QR codes are designed with security in mind:

- UUID-based identification
- Time-limited validity (default: 1 hour)
- One-time use restriction
- Course and student association

### Data Structure

The system uses structured data with validation:

```elixir
%User{
  id: "unique_id",
  name: "User Name",
  email: "user@example.com",
  role: :student,
  student_id: "STU001"  # for students only
}
```

## Testing

The system includes comprehensive tests:

```bash
mix test                    # Run all tests
mix test test/path/file     # Run specific test file
```

Test coverage includes:
- User management and permissions
- Course creation and enrollment
- Attendance marking and QR codes
- Role-based access control

## Development

### Architecture Overview

```
AcademyAttendance
├── Accounts (User Management)
├── Courses (Course Management)
├── Attendance (Attendance Tracking)
├── QRCode (QR Code Generation)
└── CLI (Command Line Interface)
```

### Adding New Features

1. Create appropriate schema modules
2. Add business logic to context modules
3. Update CLI interface for testing
4. Add comprehensive tests

### Database Integration

The current in-memory storage can be easily replaced with a database:

1. Add Ecto dependencies to mix.exs
2. Create migrations for schemas
3. Replace GenServer calls with Ecto queries
4. Update tests for database integration

## API Reference

### Core Functions

#### Accounts
```elixir
Accounts.create_admin_and_head_teacher/2
Accounts.create_user/1
Accounts.get_user_by_email/1
```

#### Courses
```elixir
Courses.create_course/2
Courses.add_teacher_to_course/3
Courses.add_student_to_course/3
```

#### Attendance
```elixir
Attendance.mark_attendance/4
Attendance.mark_attendance_with_qr/2
Attendance.generate_qr_code/2
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

