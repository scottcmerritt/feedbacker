class CreatePosts < ActiveRecord::Migration[6.1]
  def change
    create_table :posts do |t|
	    t.string :title
	    t.text :details

	    t.string :name_slug

	    # the listed creator
	    t.integer :user_id
	    # the actual creator
	    t.integer :createdby
	    t.integer :updatedby

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