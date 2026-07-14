class AddWidgetOptions < ActiveRecord::Migration[8.1]
    def change
        # Per-domain equivalents of course-site's hands_location / hands_link /
        # hands_location_bumper settings that drive the student widget variants.
        add_column :course_domains, :ask_location, :boolean, null: false, default: true
        add_column :course_domains, :link_mode, :boolean, null: false, default: false
        add_column :course_domains, :location_bumper, :boolean, null: false, default: false

        # Remembered location (course-site kept this on the user) for pre-filling
        # the form and driving the check-in bumper state.
        add_column :memberships, :last_location, :string
    end
end
