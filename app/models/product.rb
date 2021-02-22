class Product < ApplicationRecord
  has_and_belongs_to_many :categories
  validates :url, uniqueness: { case_sensitive: false }
end
