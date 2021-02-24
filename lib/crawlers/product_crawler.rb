class ProductCrawler < Mechanize
  HOMEPAGE_URL = 'https://www.tohome.com'.freeze
  CATALOG_PAGES_SELECTOR = 'div.CatalogPageLink > span#lblPageLink'.freeze
  ITEMS_SELECTOR = 'div#list > header > div.pageNo > span#lblCount'.freeze
  PRODUCTS_SELECTOR = 'span#lblProductDesc > div.mainbox'.freeze
  PRODUCT_NAME_SELECTOR = 'div.prdInfo > h2.prdTitle'.freeze
  PRODUCT_PRICE_SELECTOR = 'div.prdInfo > span.prdPrice-new'.freeze

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
    if pages_selector.nil?
      puts 'next'
    else
      pages_selector_content = pages_selector.children
      category = Category.find_by_url(category_link)
      get_products(document, category)
      unless pages_selector_content.empty?
        (1..(page_number(document) - 1)).each do
          pages_selector = document.css(CATALOG_PAGES_SELECTOR).first
          pages_selector_content = pages_selector.children.last
          next_page_link = pages_selector_content['href']
          document = page_document(next_page_link)
          get_products(document, category)
        end
      end
    end
  end

  private

  def items_number(items)
    # example: 1 - 30 of 886 items found
    # returns 886
    items.split(' ')[4].to_i
  end

  def items_per_page_number(items)
    # example: 1 - 30 of 886 items found
    # returns 30
    items.split(' ')[2].to_i
  end

  def price(price_string)
    price_string.delete("^0-9\.")
  end

  def page_number(document)
    items_info = document.css(ITEMS_SELECTOR).first.children.first.text
    total_items = items_number(items_info)
    total_items / items_per_page_number(items_info) + (total_items % items_per_page_number(items_info) ? 1 : 0)
  end

  def get_products(document, category)
    document.css(PRODUCTS_SELECTOR).each do |div|
      create_or_update_product(product_name(div), product_price(div), product_url(div), category)
    end
  end

  def product_name(div)
    div.css(PRODUCT_NAME_SELECTOR).first.children.first.text
  end

  def product_price(div)
    price(div.css(PRODUCT_PRICE_SELECTOR).first.children.first.text)
  end

  def product_url(div)
    div.css('a').first['href']
  end

  def create_or_update_product(product_name, product_price, product_url, category)
    current_product = Product.find_or_initialize_by(url: product_url)
    current_product.name = product_name
    current_product.price = product_price
    current_product.save

    category.products << current_product if !category.nil? && !category.products.include?(current_product)
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
