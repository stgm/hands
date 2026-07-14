class CreatePresences < ActiveRecord::Migration[8.1]
    def change
        create_table :presences do |t|
            t.references :course_domain, null: false, foreign_key: true
            t.references :membership, null: false, foreign_key: true
            t.string :source_label
            t.string :location
            t.datetime :connected_at, null: false
            t.datetime :last_ping_at, null: false

            t.timestamps
        end
        add_index :presences, [ :membership_id, :source_label ], unique: true
        add_index :presences, :last_ping_at
    end
end
