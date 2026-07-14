class CreateCourseDomains < ActiveRecord::Migration[8.1]
    def change
        create_table :course_domains do |t|
            t.string :name, null: false
            t.string :slug, null: false
            t.string :link_secret, null: false
            t.boolean :enrollment_open, null: false, default: true
            t.string :location_type, null: false, default: "table"

            t.timestamps
        end
        add_index :course_domains, :slug, unique: true
    end
end
