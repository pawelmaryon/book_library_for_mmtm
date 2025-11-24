class AddUniqueIndexToAuthorsName < ActiveRecord::Migration[8.0]
  def change
    add_index :authors,
              :name,
              unique: true
  end
end
