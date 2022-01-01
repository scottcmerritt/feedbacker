class CreateUserConversations < ActiveRecord::Migration[5.2]
   def change
    unless table_exists? :user_conversations
       create_table "user_conversations", force: :cascade do |t|
         t.integer "user_id"
         t.integer "target_id"
         t.integer "room_id"
         t.boolean "accepted", default: :false
         t.datetime "accepted_at"
         t.boolean "removed", default: :false
         t.datetime "removed_at"
         t.datetime "created_at"
         t.datetime "updated_at"
       end
    end

  end
end
