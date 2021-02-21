require_relative '../ crawlers/category_crawler'

namespace :crawl do
  desc 'Fetch categories'
  task categories: :environment do
    agent = CategoryCrawler.new
    agent.run
  end
end