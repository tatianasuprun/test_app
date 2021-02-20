class CreateCategoryProducts < ActiveRecord::Migration[5.2]
  def change
    create_table :categories_products, id: false do |t|
      t.bigint :category_id
      t.bigint :product_id
    end

    add_index :categories_products, :product_id
    add_index :categories_products, :category_id
  end
end
