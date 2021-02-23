class ProductCrawler < Mechanize
  HOMEPAGE_URL = 'https://www.tohome.com'.freeze
  CATEGORY_PRODUCTS_URL = 'https://www.tohome.com/catalog.aspx?catalog_id=736&catalog_name=Computer-Accessories'

  def initialize(*args)
    super(args)
    set_cookies
  end

  def pagination(category_link = '')
    document = page_document(CATEGORY_PRODUCTS_URL)

    pages_selector = document.css('div.CatalogPageLink > span#lblPageLink').first
    pages_selector_content = pages_selector.children

    page_products(category_link = '')
    unless pages_selector_content.empty?
      for i in 1..(pages_number(document) - 1)
        pages_selector = document.css('div.CatalogPageLink > span#lblPageLink').first
        pages_selector_content = pages_selector.children.last
        next_page_link = pages_selector_content['href']
        document = page_document(next_page_link)
        page_products(next_page_link)
      end
    end
  end

  private

  def prepare_string(items)
    after_needed = items.index(' items')
    l = items.size
    items.slice!(after_needed, l - 1)
    before_needed = items.index('of ')
    items.slice!(0, before_needed + 3)
    items.to_i
  end

  def pages_number(document)
    items_info = document.css('div#list > header > div.pageNo > span#lblCount').first.children.first.text
    total_items = prepare_string(items_info)
    total_items / 30 + (total_items % 30 ? 1 : 0)
  end

  def page_products(category_link = '')
    page_document(category_link).css('span#lblProductDesc > div.mainbox').each do |div|
      a = div.css('a').first
      product_name = div.css('div.prdInfo > h2.prdTitle').first.children.first.text
      product_price = div.css('div.prdInfo > span.prdPrice-new').first.children.first.text
      product_url = a['href']
      category = Category.find_by_url(CATEGORY_PRODUCTS_URL)
      current_product = Product.find_or_initialize_by(url: product_url)
      current_product.name = product_name
      current_product.price = product_price
      current_product.save
      category.products << current_product unless category.products.include?(current_product)
  
    end
  end

  def page_document(link)
    page = get(link)
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