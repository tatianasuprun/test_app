class CategoryCrawler < Mechanize
  HOMEPAGE_URL = 'https://www.tohome.com/index.aspx'.freeze
  CATEGORIES_SELECTOR = 'ul#leftnav > li'.freeze

  def initialize(*args)
    super(args)
    set_cookies
  end

  def run
    document.css(CATEGORIES_SELECTOR).each do |li|
      category_content = li.css('a').first
      subcategories = li.css('ul > li')
      category = Category.create({ name: category_content.children.first.to_s, url: category_content['href'] })
      add_subcategories(category, subcategories)
    end
  end

  private

  def add_subcategories(category, subcategories)
    previous_parent = nil
    subcategories.each do |subcat|
      subcat_content = subcat.children.first
      subcat_text = subcat_content.children.first.to_s
      if subcat_content['class'] == 'subject'
        previous_parent = category.children.create({ name: subcat_text, url: subcat_content['href'] })
      elsif subcat_content.name == 'a'
        previous_parent.children.create({ name: subcat_text, url: subcat_content['href'] })
      end
    end
  end

  def document
    page = get(HOMEPAGE_URL)
    Nokogiri::HTML(page.body)
  rescue StandardError => e
    abort("Error occured: #{e.message}")
  end

  def set_cookies
    cookie = Mechanize::Cookie.new('langCookie', 'langCookie=en-us')
    cookie.domain = '.tohome.com'
    cookie.path = '/'
    cookie_jar << cookie
  end
end