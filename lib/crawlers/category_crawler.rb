require_relative '../crawlers/base_crawler'
class CategoryCrawler < BaseCrawler
  HOMEPAGE_URL = 'https://www.tohome.com/index.aspx'.freeze
  SMARTPHONES_URL = 'https://www.tohome.com/catalog/532/Smartphones-Tablets'.freeze
  CATEGORIES_SELECTOR = 'ul#leftnav > li'.freeze

  def run
    document.css(CATEGORIES_SELECTOR).each do |li|
      category_content = li.css('a').first
      subcategories = li.css('ul > li')
      category = Category.create({ name: category_content.children.first.to_s,
                                   url: sanitize_query_string(category_content['href']) })
      add_subcategories(category, subcategories)

      correct_smartphones_link
    end
  end

  private

  def correct_smartphones_link
    smartphones = Category.find_by_name('Smartphones l Tablets')
    unless smartphones.nil?
      smartphones.url = SMARTPHONES_URL
      smartphones.save
    end
  end

  def add_subcategories(category, subcategories)
    previous_parent = nil
    subcategories.each do |subcat|
      subcat_content = subcat.children.first
      subcat_text = subcat_content.children.first.to_s
      if subcat_content['class'] == 'subject'
        previous_parent = category.children.create({ name: subcat_text, url: sanitize_query_string(subcat_content['href']) })
      elsif subcat_content.name == 'a'
        previous_parent.children.create({ name: subcat_text, url: sanitize_query_string(subcat_content['href']) })
      end
    end
  end

  def sanitize_query_string(url)
    uri = URI.parse(url)

    query = Rack::Utils.parse_query(uri.query)
    query.except!('page')

    uri.query = Rack::Utils.build_query(query)
    uri.to_s
  end

  def document
    page = get(HOMEPAGE_URL)
    Nokogiri::HTML(page.body)
  rescue StandardError => e
    abort("Error occured: #{e.message}")
  end
end