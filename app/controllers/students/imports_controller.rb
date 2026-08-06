class Students::ImportsController < ApplicationController
    include DomainScoped

    before_action :require_senior

    # GET /<slug>/students/import — the roster page: who is enrolled, and the box
    # to paste a new list into
    def new
        @student_count = current_course_domain.memberships.students.count
        @group_names = current_course_domain.group_names
    end

    # POST /<slug>/students/import — parse the pasted list and show what it would
    # do. Nothing is written yet: the import creates accounts, so a mis-detected
    # column has to be visible before it happens.
    def create
        @text = params[:text].to_s
        if @text.strip.empty?
            redirect_to domain_students_import_path(current_course_domain.slug), alert: "Paste the student list first" and return
        end

        @import = RosterImport.new(current_course_domain, @text)

        if @import.email_column_missing?
            redirect_to domain_students_import_path(current_course_domain.slug),
                alert: "No email column found. The list needs a column headed Email." and return
        end

        if @import.rows.empty?
            redirect_to domain_students_import_path(current_course_domain.slug), alert: "That list has no rows" and return
        end

        render :preview
    end

    # POST /<slug>/students/import/confirm — apply the previewed list. The text
    # rides along in the form, so nothing has to be stored between the two steps;
    # rosters are small enough for that.
    def confirm
        counts = RosterImport.new(current_course_domain, params[:text]).import!

        redirect_to domain_students_import_path(current_course_domain.slug),
            notice: "Imported #{helpers.pluralize(counts[:new_user], 'new account')}, " \
                    "#{helpers.pluralize(counts[:new_membership], 'existing account')} enrolled, " \
                    "#{helpers.pluralize(counts[:group_change], 'group')} changed"
    end
end
