class AddGroupToMemberships < ActiveRecord::Migration[8.0]
    def change
        # A student's lab group within this course. Pure labelling, scoped to the
        # course, nil when the course has no groups or the student has none.
        add_column :memberships, :group, :string
        add_index :memberships, [ :course_domain_id, :group ]

        # The group tab a staff member last selected in the queue, so TAs land on
        # their own group across sessions and devices.
        add_column :memberships, :queue_group_filter, :string
    end
end
