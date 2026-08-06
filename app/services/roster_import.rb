require "csv"

# Reads a student export CSV and enrols its rows in one course domain, assigning
# each student's group. Unlike course-site, accounts are created here as well:
# a row for an unknown email gets a user record, so a teacher can hand out a
# roster before anyone has logged in.
#
# Parsing and applying are separate on purpose. #rows is a dry run the teacher
# confirms in the browser, so a mis-detected column shows up before any account
# exists; #import! then applies exactly what was shown.
class RosterImport
    # Header aliases, so common Dutch and English exports work unconfigured.
    # Compared after downcasing and squashing whitespace/punctuation.
    HEADERS = {
        email: %w[email mail emailadres],
        name: %w[name naam fullname volledigenaam displayname],
        first_name: %w[firstname voornaam givenname],
        middle_name: %w[middlename tussenvoegsel],
        last_name: %w[lastname surname achternaam familyname],
        student_number: %w[studentnumber studentnummer studentid],
        group: %w[group groep groupname groepsnaam werkgroep class klas]
    }.freeze

    Row = Struct.new(:line, :email, :name, :student_number, :group, :status, :error, keyword_init: true) do
        def ok? = error.nil?
    end

    attr_reader :course_domain, :text

    def initialize(course_domain, text)
        @course_domain = course_domain
        @text = text.to_s
    end

    # True when the file had no recognizable email column: nothing can be done
    # with it, and saying so beats reporting every row as an error.
    def email_column_missing?
        parse
        @email_column_missing
    end

    def rows
        parse
        @rows
    end

    def counts
        rows.each_with_object(Hash.new(0)) { |row, counts| counts[row.status] += 1 }
    end

    def groups
        rows.filter_map(&:group).uniq
    end

    # Applies every non-error row. Existing memberships keep their role, so a TA
    # who also appears on the roster is not demoted to student.
    def import!
        ActiveRecord::Base.transaction do
            rows.select(&:ok?).each { |row| apply(row) }
        end
        counts
    end

    private

    def apply(row)
        user = User.find_by(email: row.email) ||
            User.create!(email: row.email, name: row.name, student_number: row.student_number)

        # Never overwrite what a student filled in themselves; only fill blanks.
        user.name = row.name if user.name.blank? && row.name.present?
        user.student_number = row.student_number if user.student_number.blank? && row.student_number.present?
        user.save! if user.changed?

        membership = course_domain.memberships.find_by(user: user) ||
            course_domain.memberships.new(user: user, role: :student, source_label: "import")
        membership.group = row.group
        membership.save!
    end

    def parse
        return if defined?(@rows)

        @rows = []
        @email_column_missing = false
        return if text.strip.empty?

        table = CSV.parse(text, headers: true, col_sep: delimiter, skip_blanks: true)
        mapping = header_mapping(table.headers)

        if mapping[:email].nil?
            @email_column_missing = true
            return
        end

        seen = Set.new
        parsed = table.filter_map.with_index(2) do |csv_row, line|
            row = build_row(csv_row, mapping, line)
            next if row.nil?

            row.error ||= "duplicate row for #{row.email}" unless seen.add?(row.email)
            row
        end

        assign_statuses(parsed)
        @rows = parsed
    rescue CSV::MalformedCSVError => e
        @rows = []
        @error = e.message
    end

    def build_row(csv_row, mapping, line)
        email = csv_row[mapping[:email]].to_s.strip.downcase
        name = full_name(csv_row, mapping)
        row = Row.new(
            line: line,
            email: email,
            name: name,
            student_number: value(csv_row, mapping, :student_number),
            group: value(csv_row, mapping, :group)
        )

        # A wholly empty line is not worth reporting as an error.
        return nil if email.blank? && name.blank? && row.group.blank?

        row.error = email.blank? ? "no email" : "not an email address" unless email.match?(URI::MailTo::EMAIL_REGEXP)
        row
    end

    # Separate name columns are joined in speaking order, so a Dutch export's
    # "van de" middle column lands between the first and last name.
    def full_name(csv_row, mapping)
        return value(csv_row, mapping, :name) if mapping[:name]

        parts = [ :first_name, :middle_name, :last_name ].map { |field| value(csv_row, mapping, field) }
        parts.compact.join(" ").presence
    end

    def value(csv_row, mapping, field)
        return nil unless mapping[field]

        csv_row[mapping[field]].to_s.strip.presence
    end

    # Statuses in one pass over two lookups rather than a query per row, so a
    # full-cohort preview stays cheap.
    def assign_statuses(parsed)
        emails = parsed.select(&:ok?).map(&:email)
        users = User.where(email: emails).index_by(&:email)
        existing_groups = course_domain.memberships.where(user_id: users.values.map(&:id)).pluck(:user_id, :group).to_h

        parsed.each do |row|
            next unless row.ok?

            user = users[row.email]
            row.status =
                if user.nil? then :new_user
                elsif !existing_groups.key?(user.id) then :new_membership
                elsif existing_groups[user.id] == row.group.presence then :unchanged
                else :group_change
                end
        end
    end

    # Maps our field names onto the actual header strings in the file.
    def header_mapping(headers)
        HEADERS.each_with_object({}) do |(field, aliases), mapping|
            mapping[field] = headers.compact.find { |header| aliases.include?(normalize_header(header)) }
        end
    end

    def normalize_header(header)
        header.to_s.downcase.gsub(/[^a-z]/, "")
    end

    # Pasting out of a spreadsheet gives tabs, Dutch exports are commonly
    # semicolon-separated: take whichever separator occurs most on the header
    # line, falling back to a comma when the header has only one column.
    def delimiter
        header = text.lines.first.to_s
        [ "\t", ";", "," ].max_by { |candidate| header.count(candidate) }
            .then { |best| header.count(best).zero? ? "," : best }
    end
end
