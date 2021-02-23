require_relative '../crawlers/category_crawler'
require_relative '../crawlers/product_crawler'

namespace :crawl do
  desc 'Fetch categories'
  task categories: :environment do
    agent = CategoryCrawler.new
    agent.run
  end

  desc 'Fetch products'
  task products: :environment do
    agent = ProductCrawler.new

    agent.run
  end
end