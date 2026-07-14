class AddLocales < ActiveRecord::Migration[8.1]
    def change
        # The domain's own language (standalone pages, and the fallback).
        add_column :course_domains, :locale, :string, null: false, default: "en"
        # The locale handed over by the course-site this student arrived from, so
        # realtime broadcasts (which have no request context) render in it too.
        add_column :memberships, :locale, :string
    end
end
