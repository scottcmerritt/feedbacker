class CreateRooms < ActiveRecord::Migration[5.2]
   def change
    unless table_exists? :rooms
       
       unless table_exists? :room_messages
        create_table "room_messages", force: :cascade do |t|
          t.bigint "room_id"
          t.bigint "user_id"
          t.text "message"
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
          t.string "icon_css"
          t.boolean "removed", default: false
          t.integer "removed_by"
          t.datetime "removed_at"
          t.integer "removed_code"
          t.integer "parent_id", default: 0
          t.integer "child_total", default: 0
          t.index ["room_id"], name: "index_room_messages_on_room_id"
          t.index ["user_id"], name: "index_room_messages_on_user_id"
        end
      end

      unless table_exists? :room_users
        create_table "room_users", force: :cascade do |t|
          t.integer "room_id"
          t.integer "user_id"
          t.string "user_alias"
          t.integer "org_id"
          t.integer "role_id"
          t.string "role_title"
          t.boolean "is_active", default: true
          t.datetime "created_at"
          t.datetime "updated_at"
          t.boolean "approved", default: true
          t.datetime "approved_at"
          t.integer "approved_by"
          t.boolean "archived", default: false
          t.datetime "archived_at"
          t.integer "archived_by"
          t.boolean "removed", default: false
          t.datetime "removed_at"
          t.integer "removed_by"
          t.boolean "hide_user", default: false
          t.boolean "is_pending", default: false
          t.boolean "is_flagged", default: false
          t.string "bg_color"
          t.index ["org_id"], name: "idx_room_users_org_id_ix"
          t.index ["room_id"], name: "idx_room_users_room_id_ix"
          t.index ["user_id"], name: "idx_room_users_user_id_ix"
        end
      end

      unless table_exists? :rooms
        create_table "rooms", force: :cascade do |t|
          t.string "name"
          t.datetime "created_at", null: false
          t.datetime "updated_at", null: false
          t.integer "item_id"
          t.integer "describe_id"
          t.integer "idea_id"
          t.integer "post_id"
          t.boolean "is_public", default: true
          t.boolean "is_global", default: false
          t.boolean "title_global", default: false
          t.boolean "users_global", default: false
          t.boolean "messages_global", default: false
          t.boolean "approved", default: true
          t.datetime "approved_at"
          t.integer "approved_by"
          t.boolean "archived", default: false
          t.datetime "archived_at"
          t.integer "archived_by"
          t.boolean "removed", default: false
          t.datetime "removed_at"
          t.integer "removed_by"
          t.boolean "hide_user", default: false
          t.boolean "hide_users", default: false
          t.datetime "publish_date"
          t.boolean "is_pending", default: false
          t.boolean "is_flagged", default: false
          t.string "mc_guid", limit: 255
          t.integer "parent_id"
          t.integer "org_id"
          t.integer "user_id"
          t.integer "admin_org_id"
          t.integer "promoter_org_id"
          t.integer "county_id"
          t.integer "city_id"
          t.integer "state_id"
          t.integer "country_id"
          t.text "purpose"
          t.text "why_join"
          t.string "icon_css"
          t.integer "createdby"
          t.string "createdby_mc_guid"
          t.integer "sash_id"
          t.integer "level", default: 0
          t.integer "room_type", default: 1
          t.boolean "is_event", default: false
          t.datetime "start_time"
          t.datetime "end_time"
          t.string "share_key"
          t.boolean "is_chat", default: false
          t.boolean "closed", default: false
          t.datetime "closed_at"
          t.integer "closed_by"
          t.index ["city_id"], name: "index_rooms_on_city_id"
          t.index ["country_id"], name: "index_rooms_on_country_id"
          t.index ["county_id"], name: "index_rooms_on_county_id"
          t.index ["describe_id"], name: "index_rooms_on_describe_id"
          t.index ["item_id"], name: "index_rooms_on_item_id"
          t.index ["name"], name: "index_rooms_on_name", unique: true
          t.index ["org_id"], name: "index_rooms_on_org_id"
          t.index ["parent_id"], name: "index_rooms_on_parent_id"
          t.index ["state_id"], name: "index_rooms_on_state_id"
          t.index ["user_id"], name: "index_rooms_on_user_id"
        end
      end
    end

  end
end

