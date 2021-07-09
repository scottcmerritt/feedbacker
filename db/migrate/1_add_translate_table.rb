class AddTranslateTable < ActiveRecord::Migration[6.1]
  def change
     create_table :translates do |t|
      t.boolean :active, default: :true

      t.integer :translate_key_id

      # used to list any item in the database, like a BOOK
      t.string :lang

      t.string :phrase
    
      t.integer :user_id # creator
      t.boolean :approved
      t.datetime :approved_at
      t.integer :approved_by

      t.timestamps
    end


    create_table :translate_keys do |t|
      t.string :tdomain
      t.string :tkey
      t.integer :createdby
      t.boolean :is_public
      t.boolean :is_global
      t.boolean :approved
      t.datetime :approved_at
      t.integer :approved_by
      t.boolean :removed
      t.integer :removed_by
      t.datetime :removed_at

      t.timestamps
    end



  end
end



