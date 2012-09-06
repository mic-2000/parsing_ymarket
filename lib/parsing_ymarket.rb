require "parsing_ymarket/version"
require 'nokogiri'
require 'open-uri'


module ParsingYmarket

class Parsing
  attr_reader :product, :products

  BASIC_URL='http://market.yandex.ua'

  def url_filter(url)
    pagin_url = pagination(format_url(url))
    products_url = product_url(pagin_url)
    @products = []
    products_url.each do |value|  
      doc = open_url(value)
      @products << Product.new(doc)      
    end
    @products
  end

  def find(name)
    search_url = "http://market.yandex.ua/search.xml?text=#{URI.escape(name)}"
    doc = open_url(search_url)
    url = []
    doc.css('div.b-offers').each do |product_name|
      if product_link?(product_name.css('h3.b-offers__title a').first['href'])
        url << product_name.css('h3.b-offers__title a').first['href']
      end    
    end
    doc = open_url(url.first)
    @product = Product.new(doc)
  end


  private

  def product_url(list_url)
    products_url = []
    list_url.each do |url|
      doc = open_url(url)
      doc.css('div.b-offers').each do |product_name|
        unless product_name.css('h3.b-offers__title a').size == 0 
          products_url << product_name.css('h3.b-offers__title a').first['href'] unless modelid(product_name.css('h3.b-offers__title a').first['href']).nil?
        end
      end
    end
    products_url
  end

  def open_url(url)   
    data = open(format_url(url))
    doc = Nokogiri::XML(data)
  end

  def format_url(url)
    return url if url.include?("market.yandex.")    
    return BASIC_URL + '/' + url unless url[0] == '/'
    BASIC_URL+url
  end

  def modelid(url)
    url[/(modelid=)\d+/][8..-1] if !url[/(modelid=)\d+/].nil?
  end

  def product_link?(url)
    url.to_s.include?('modelid')
  end

  def pagination(url_category)
    next_url = [url_category]
    url=''
    while url != next_url.last do
      url=next_url.last
      data = open(format_url(url))
      doc = Nokogiri::HTML(data)
      next_url << [url_category] unless next_url.include?(url_category)
      doc.css('div.b-pager__pages').search('a').each do |url|
        next_url << url['href'] unless next_url.include?(url['href'])
      end
    end
    next_url
  end

  class Product<Parsing
  	attr_reader :model_id, :name, :image, :description, :characteristics, :comments

  	def initialize(html)
  		if  html.css("p.b-model-friendly__title a").empty?
  	  	raise 'incorrect page'
  	  end
  	  @model_id = modelid(html.css("p.b-model-friendly__title a").first['href'])
  	  @name = html.css('h1.b-page-title').children.first.inner_text
  	  @image = html.css(".b-model-pictures").css("img").first['src'] if html.css(".b-model-pictures").css("img").first['src']
  	  @discription = html.css("ul.b-vlist li").collect do |discr|
  	  	discr.inner_text+"\n"
  	  end
  	  @characteristics = parse_characteristics(html.css("p.b-model-friendly__title a").first['href'])
  	  @comments = parse_comments(html)
    end

    #парсилка характеристик со страницы товара
    def parse_characteristics(url)
      if !url.include?('model-spec.xml')
        puts 'incorrect link'
        return
      end
      doc = open_url(url)
      res = Array.new()
      doc.css('table.b-properties').each do |table|
        table.css('tr').each do |tr|
          if tr.css('th').first['class'].include?('b-properties__label')
            res << Hash[tr.css('th').inner_text, tr.css('td').inner_text]
          end
        end
      end
      res
    end

  # парсилка коментов со страницы товара
    def parse_comments(doc)
      res = Array.new
      if !doc.css('a.b-user-opinions__all').empty?
        all_comments=pagination(doc.css('a.b-user-opinions__all').first['href'])
        all_comments.each do |url|
          doc = open_url(url)
          doc.css('div.b-grade').each do |comment|
            res << Comment.new(comment)
          end
        end
      elsif !doc.css('div.b-opinions').empty?
        doc.css('div.b-opinions').each do |comment|
          res <<  Comment.new(comment)
        end
      end
      res.uniq
    end
  end



  class Comment<Parsing
  	attr_reader :user, :opinion, :comment, :rating

  	def initialize(comment)
  	  unless comment.class == Nokogiri::XML::Element	
  	  	raise ArgumentError
  	  end

  	  @user = comment.at_css('b.b-user').inner_text
  	  if comment.css('p.user-opinion').empty?
  	  	@opinion = comment.css('div.b-opinions__text').collect do |commm|
  			  commm.inner_text+"\n" if !commm.css('p').empty?
  		  end
  	  else
  	  	@opinion = comment.css('p.user-opinion').collect do |commm|
  			  commm.inner_text+"\n"
  		  end	  		
  	  end
  	  if comment.css('div.b-opinions__text').empty?
  	  	@comment = comment.css('div.data').css('p').last.inner_text if comment.css('div.data').css('p').last['class'].nil?
  	  else
  	  	@comment = comment.css('div.b-opinions__text').collect do |commm|
  			  commm.inner_text+"\n" if commm.css('p').empty?
  		  end
  	  end		
  	  @rating = comment.css('div.grade').css('span.b-rating__star-other').size
  	end
  end

end
end
