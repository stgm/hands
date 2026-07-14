class CreateMemberships < ActiveRecord::Migration[8.1]
    def change
        create_table :memberships do |t|
            t.references :user, null: false, foreign_key: true
            t.references :course_domain, null: false, foreign_key: true
            t.integer :role, null: false, default: 0
            t.string :source_label
            t.references :invited_by, null: true, foreign_key: { to_table: :users }
            t.datetime :last_seen_at
            t.datetime :available_until

            t.timestamps
        end
        add_index :memberships, [ :user_id, :course_domain_id ], unique: true
    end
end
