class AddCreatedByToCourseDomains < ActiveRecord::Migration[8.1]
    def change
        add_reference :course_domains, :created_by, null: true, index: true,
            foreign_key: { to_table: :users }
    end
end
