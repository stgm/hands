class CreateInvitations < ActiveRecord::Migration[8.1]
    def change
        create_table :invitations do |t|
            t.references :course_domain, null: false, foreign_key: true
            t.string :email, null: false
            t.integer :role, null: false, default: 1
            t.string :token, null: false
            t.references :invited_by, null: true, foreign_key: { to_table: :users }
            t.datetime :accepted_at

            t.timestamps
        end
        add_index :invitations, :token, unique: true
        add_index :invitations, [ :course_domain_id, :email ]
    end
end
