class ProductCrawler < Mechanize
  HOMEPAGE_URL = 'https://www.tohome.com'.freeze
  CATALOG_PAGES_SELECTOR = 'div.CatalogPageLink > span#lblPageLink'.freeze
  ITEMS_SELECTOR = 'div#list > header > div.pageNo > span#lblCount'.freeze

  def initialize(*args)
    super(args)
    set_cookies
  end

  def run
    categories = Category.all
    categories.each do |category|
      category_pages(category.url)
    end
  end

  def category_pages(category_link)
    document = page_document(category_link)
    puts category_link

    pages_selector = document.css(CATALOG_PAGES_SELECTOR).first
    puts 'next' if pages_selector.nil?
    unless pages_selector.nil?
      pages_selector_content = pages_selector.children
      category = Category.find_by_url(category_link)
      page_products(document, category)
      unless pages_selector_content.empty?
        for i in 1..(page_number(document) - 1)
          pages_selector = document.css(CATALOG_PAGES_SELECTOR).first
          pages_selector_content = pages_selector.children.last
          next_page_link = pages_selector_content['href']
          document = page_document(next_page_link)
          page_products(document, category)
        end
      end
    end
  end

  private

  def items_number(items)
    after_needed = items.index(' items')
    l = items.size
    items.slice!(after_needed, l - 1)
    before_needed = items.index('of ')
    items.slice!(0, before_needed + 3)
    items.to_i
  end

  def price(price_string)
    price_string.delete("^0-9\.")
  end

  def page_number(document)
    items_info = document.css(ITEMS_SELECTOR).first.children.first.text
    total_items = items_number(items_info)
    total_items / 30 + (total_items % 30 ? 1 : 0)
  end

  def page_products(document, category)
    document.css('span#lblProductDesc > div.mainbox').each do |div|
      a = div.css('a').first
      product_name = div.css('div.prdInfo > h2.prdTitle').first.children.first.text
      product_price_string = div.css('div.prdInfo > span.prdPrice-new').first.children.first.text
      product_price = price(product_price_string)
      product_url = a['href']
      add_product(product_name, product_price, product_url, category)
    end
  end

  def add_product(product_name, product_price, product_url, category)
    current_product = Product.find_or_initialize_by(url: product_url)
    current_product.name = product_name
    current_product.price = product_price
    current_product.save

    if !category.nil? && !category.products.include?(current_product)
      category.products << current_product
    end
  end

  def page_document(category_link)
    page = get(category_link)
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