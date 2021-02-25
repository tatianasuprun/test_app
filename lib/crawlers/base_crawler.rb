class BaseCrawler < Mechanize
  def initialize(*args)
    super(args)
    set_cookies
  end

  private 

  def set_cookies
    cookie = Mechanize::Cookie.new('langCookie', 'langCookie=en-us')
    cookie.domain = '.tohome.com'
    cookie.path = '/'
    cookie_jar << cookie
  end
end