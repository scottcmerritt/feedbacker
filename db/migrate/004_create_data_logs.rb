class CreateDataLogs < ActiveRecord::Migration[5.2]
   def change
    unless table_exists? :data_logs
      create_table "data_logs", force: :cascade do |t|
        t.string "domain" #category of info
        t.string "key" # series
        t.string "note"
        t.text "value"
        t.integer "created_by"
        t.datetime "created_at"
        t.datetime "updated_at"
      end
    end

    unless table_exists? :archives
      # used for archiving big relational rows 
      # could be used for authors, orgs and maybe sources (and even impressions) (upon removal)
      create_table "archives", force: :cascade do |t|
        t.string "archive_type"
        t.jsonb "data" #cache of data
        t.string "note"
        t.integer "created_by"
        t.datetime "created_at"
        t.datetime "updated_at"
      end
    end

  end
end