class CreateTags < ActiveRecord::Migration[5.2]
   def change
    unless table_exists? :tags

    end

  end
end