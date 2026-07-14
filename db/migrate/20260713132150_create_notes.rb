class CreateNotes < ActiveRecord::Migration[8.1]
    def change
        create_table :notes do |t|
            t.references :course_domain, null: false, foreign_key: true
            t.references :membership, null: false, foreign_key: true
            t.bigint :author_membership_id
            t.boolean :log, null: false, default: false

            t.timestamps
        end
        add_index :notes, :author_membership_id
        add_foreign_key :notes, :memberships, column: :author_membership_id
        add_index :notes, [ :course_domain_id, :membership_id ]
    end
end
