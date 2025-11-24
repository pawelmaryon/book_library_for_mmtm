class CreateBooks < ActiveRecord::Migration[8.0]
  def change
    create_table :books do |t|
      t.string :title
      t.string :isbn
      t.integer :publication_year
      t.integer :pages
      t.integer :price_pence
      t.string :currency
      t.references :author, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.integer :series_position
      t.string :series_name

      t.timestamps
    end
  end
end
