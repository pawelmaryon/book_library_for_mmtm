class AddUniqueIndexToBooksIsbn < ActiveRecord::Migration[8.0]
  def change
    add_index :books,
              :isbn,
              unique: true,
              where: "isbn IS NOT NULL"
  end
end
