require "test_helper"

class NoteTest < ActiveSupport::TestCase
    setup do
        @domain = course_domains(:algorithms)
        @student = memberships(:student_algorithms)
        @ta = memberships(:ta_algorithms)
    end

    test "a written note stores rich text and an author" do
        note = @domain.notes.create!(membership: @student, author: @ta, text: "Struggling with recursion")
        assert_equal "Struggling with recursion", note.text.to_plain_text
        assert_equal @ta, note.author
        assert_not note.log?
    end

    test "raising a hand writes a log note, kept out of written notes" do
        assert_difference -> { @domain.notes.log_entries.count }, 1 do
            Hand.create!(course_domain: @domain, membership: @student, help_question: "q")
        end
        assert @domain.notes.written.none?
    end

    test "written and log scopes partition notes" do
        @domain.notes.create!(membership: @student, author: @ta, text: "written one")
        Hand.create!(course_domain: @domain, membership: @student, help_question: "q")
        assert_equal 1, @domain.notes.written.count
        assert_operator @domain.notes.log_entries.count, :>=, 1
    end
end
