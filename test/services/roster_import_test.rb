require "test_helper"

class RosterImportTest < ActiveSupport::TestCase
    setup { @domain = course_domains(:algorithms) }

    def import(text)
        RosterImport.new(@domain, text)
    end

    test "creates an account, a membership and a group for an unknown email" do
        csv = "Email,Name,Group\nnew@student.uva.nl,New Student,Group 1\n"

        assert_difference [ "User.count", "@domain.memberships.count" ], 1 do
            import(csv).import!
        end

        membership = @domain.membership_for(User.find_by(email: "new@student.uva.nl"))
        assert membership.student?
        assert_equal "Group 1", membership.group
        assert_equal "import", membership.source_label
        assert_equal "New Student", membership.user.name
    end

    test "enrols an existing account without creating a user" do
        csv = "Email,Group\noutsider@example.org,Group 2\n"

        assert_no_difference "User.count" do
            assert_difference "@domain.memberships.count", 1 do
                import(csv).import!
            end
        end

        assert_equal "Group 2", @domain.membership_for(users(:outsider)).group
    end

    test "sets the group on an existing membership without touching its role" do
        csv = "Email,Group\n#{users(:ta).email},Group 3\n"
        import(csv).import!

        membership = memberships(:ta_algorithms).reload
        assert membership.assistant?
        assert_equal "Group 3", membership.group
    end

    test "does not overwrite a name the student set themselves" do
        csv = "Email,Name\n#{users(:student).email},Someone Else\n"
        import(csv).import!

        assert_equal "Sam Student", users(:student).reload.name
    end

    test "fills a blank name from the file" do
        users(:outsider).update!(name: nil)
        import("Email,Name\noutsider@example.org,Olive Outsider\n").import!

        assert_equal "Olive Outsider", users(:outsider).reload.name
    end

    test "accepts Dutch headers and semicolons" do
        csv = "E-mailadres;Naam;Studentnummer;Werkgroep\nnieuw@student.uva.nl;Nieuwe Student;87654321;Groep 4\n"
        import(csv).import!

        user = User.find_by(email: "nieuw@student.uva.nl")
        assert_equal "87654321", user.student_number
        assert_equal "Groep 4", @domain.membership_for(user).group
    end

    test "joins separate first and last name columns" do
        import("Email,First name,Last name\nsplit@student.uva.nl,Split,Name\n").import!

        assert_equal "Split Name", User.find_by(email: "split@student.uva.nl").name
    end

    test "reads a tab-separated paste out of a spreadsheet" do
        csv = <<~TSV
            StudentID\tUvAnetID\tLastName\tMiddleName\tFirstName\tEmail\tGender\tGroup
            91819\t91819\tTest\tvan de\tMarijn\tmarijn@student.uva.nl\tM\tGroep 4
            91820\t91820\tTest\t\tSam\tsam@student.uva.nl\tM\tGroep 1
        TSV
        import(csv).import!

        marijn = User.find_by(email: "marijn@student.uva.nl")
        assert_equal "Marijn van de Test", marijn.name
        assert_equal "91819", marijn.student_number
        assert_equal "Groep 4", @domain.membership_for(marijn).group
        assert_equal "Sam Test", User.find_by(email: "sam@student.uva.nl").name
    end

    test "a single-column list still parses" do
        import("Email\nsolo@student.uva.nl\n").import!

        assert @domain.membership_for(User.find_by(email: "solo@student.uva.nl"))
    end

    test "a blank group cell means no group" do
        import("Email,Group\nblank@student.uva.nl,\n").import!

        assert_nil @domain.membership_for(User.find_by(email: "blank@student.uva.nl")).group
    end

    test "reports bad and duplicate rows instead of importing them" do
        csv = "Email,Group\nnotanemail,Group 1\n,Group 1\ndup@student.uva.nl,Group 1\ndup@student.uva.nl,Group 2\n"
        rows = import(csv).rows

        assert_equal [ "not an email address", "no email", nil, "duplicate row for dup@student.uva.nl" ], rows.map(&:error)

        assert_difference "User.count", 1 do
            import(csv).import!
        end
        assert_equal "Group 1", @domain.membership_for(User.find_by(email: "dup@student.uva.nl")).group
    end

    test "statuses describe what each row would do" do
        memberships(:student_algorithms).update!(group: "Group 1")
        csv = <<~CSV
            Email,Group
            #{users(:student).email},Group 1
            #{users(:student).email.sub("student@", "sam@")},Group 1
            outsider@example.org,Group 2
        CSV

        assert_equal [ :unchanged, :new_user, :new_membership ], import(csv).rows.map(&:status)

        memberships(:student_algorithms).update!(group: "Group 9")
        assert_equal :group_change, import(csv).rows.first.status
    end

    test "a file without an email column is refused" do
        assert import("Name,Group\nSomeone,Group 1\n").email_column_missing?
        assert_not import("Email\nsomeone@example.org\n").email_column_missing?
    end

    test "an empty file yields no rows" do
        assert_empty import("").rows
        assert_empty import("Email,Group\n").rows
    end

    test "lists the groups found in the file" do
        csv = "Email,Group\na@example.org,Group 2\nb@example.org,Group 10\nc@example.org,Group 2\n"

        assert_equal [ "Group 2", "Group 10" ], import(csv).groups
    end
end
