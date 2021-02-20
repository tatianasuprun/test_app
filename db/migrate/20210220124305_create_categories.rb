class CreateCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :categories do |t|
      t.string :name
      t.string :url, index: true

      t.integer :parent_id, null: true, index: true
      t.integer :lft, null: true, index: true
      t.integer :rgt, null: true, index: true
      t.integer :depth, null: false, default: 0
      t.integer :children_count, null: false, default: 0 

      t.timestamps
    end
  end
end
