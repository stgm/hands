# Idempotent demo data for local development / manual verification.
admin = User.find_or_create_by!(email: "admin@example.com") do |u|
    u.name = "Admin Ada"
    u.admin = true
end

domain = CourseDomain.find_or_create_by!(slug: "demo") do |d|
    d.name = "Demo Course"
    d.enrollment_open = true
    d.location_type = "table"
end

student = User.find_or_create_by!(email: "student@example.com") { |u| u.name = "Sam Student"; u.student_number = "12345678" }
ta      = User.find_or_create_by!(email: "ta@example.com") { |u| u.name = "Tanya TA" }
teacher = User.find_or_create_by!(email: "teacher@example.com") { |u| u.name = "Terry Teacher" }

domain.memberships.find_or_create_by!(user: student) { |m| m.role = :student }
domain.memberships.find_or_create_by!(user: ta) { |m| m.role = :assistant }
domain.memberships.find_or_create_by!(user: teacher) { |m| m.role = :teacher }

puts "Seeded: admin=#{admin.email}, domain=/#{domain.slug}, student/ta/teacher memberships. link_secret=#{domain.link_secret}"
