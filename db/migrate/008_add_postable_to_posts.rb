class AddPostableToPosts < ActiveRecord::Migration[6.1]
  def change
    add_reference :posts, :postable, polymorphic: true, index: true
  end
end
