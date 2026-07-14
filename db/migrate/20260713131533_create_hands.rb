class CreateHands < ActiveRecord::Migration[8.1]
    def change
        create_table :hands do |t|
            t.references :course_domain, null: false, foreign_key: true
            t.references :membership, null: false, foreign_key: true
            t.bigint :assist_membership_id
            t.string :subject
            t.text :help_question
            t.string :location
            t.text :note
            t.string :evaluation
            t.string :source_label
            t.boolean :done, null: false, default: false
            t.boolean :success, null: false, default: false
            t.boolean :helpline, null: false, default: false
            t.datetime :claimed_at
            t.datetime :closed_at

            t.timestamps
        end
        add_index :hands, :assist_membership_id
        add_index :hands, [ :course_domain_id, :done ]
        add_foreign_key :hands, :memberships, column: :assist_membership_id
    end
end
