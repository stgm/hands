class AddClosedByToHands < ActiveRecord::Migration[8.1]
    def change
        add_column :hands, :closed_by_membership_id, :bigint
        add_index :hands, :closed_by_membership_id
        add_foreign_key :hands, :memberships, column: :closed_by_membership_id
    end
end
