require "parsing_ymarket/version"
require 'nokogiri'
require 'open-uri'

class ParsingYmarket
	BASIC_URL='http://market.yandex.ua'

    attr_reader :name, :model_id, :image, :images, :description, :thumb, :characteristics, :comment


	def self.name
		"parsing_ymarket"
	end	

	def initialize (url)
	  if url.nil?
	  	return
	  end

      if !product_link?(url)
      	parse_product(url)
      	return
      end	

      parsing_category(url)

	end

	def parsing_category(url)

	  pagin_url = pagination(format_url(url))

	  products = product_url(pagin_url)

	  products.each_value do |value|	
	  	value.merge!(parse_product(value[:url]))
	  end

	  # product={}
	  # doc.css('h3.b-offers__title a').each do |product_name|
	  #   product[product_name.inner_text.to_sym](product_name['href'])
	  # end
	  # puts product

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

	def format_url(url)
	  return url if url.include?(".yandex.")		
	  return BASIC_URL + '/' + url unless url[0] == '/'
	  BASIC_URL+url
	end

	def open_url(url)		
		data = open(format_url(url))
	    doc = Nokogiri::HTML(data)
	end

	def product_url(list_url)

	  products={}

	  list_url.each do |url|

	    doc = Nokogiri::HTML(open(format_url(url)))

	    doc.css('div.b-offers').each do |product_name|
	      if !modelid(product_name.css('h3.b-offers__title a').first['href']).nil?
	      	products.merge!(modelid(product_name.css('h3.b-offers__title a').first['href']).to_sym => {
	      	  :title => product_name.css('h3.b-offers__title a').inner_text,
	      	  :url => product_name.css('h3.b-offers__title a').first['href'],
	      	  :image_small => product_name.children.first['src'],
	      	  :short_descr => product_name.css('p.b-offers__spec').inner_text  })
	      end
	    end

	  end

	  products
	end

	# Парсим товар
	def parse_product(url)
      if !product_link?(url)
      	puts 'incorrect link'
      	return
      end		
	  doc = open_url(url)
	  @model_id = modelid(url)
	  @name = doc.css('h1.b-page-title').children.first.inner_text
	  @image = doc.css(".b-model-pictures").css("img").first['src'] if doc.css(".b-model-pictures").css("img").first['src']
	  @discription = doc.css("ul.b-vlist li").collect do |discr|
	  	discr.inner_text+"\n"
	  end
	  @characteristics = parse_characteristics(doc.css("p.b-model-friendly__title a").first['href'])
	  @comment = parse_comments(url)
	  res = Hash[:name => @name, :image => @image, :discription => @discription, :characteristics =>@characteristics, :comment => @comment]
	end

  # парсилка характеристик со страницы товара
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
	def parse_comments(url)	
	  if !product_link?(url)
      	puts 'incorrect link'
      	return
      end			
	  doc = open_url(url)		
	  res = Array.new		
	  if !doc.css('a.b-user-opinions__all').empty?
		all_comments=pagination(doc.css('a.b-user-opinions__all').first['href'])
		all_comments.each do |url|
		  doc = open_url(url)
		  doc.css('div.b-grade').each do |comment|
		  	res << parse_comment(comment)
		  end
		end
	  elsif !doc.css('div.b-opinions').empty?
	    doc.css('div.b-opinions').each do |comment|
	      data = Hash.new	
	  	  data[:user] = comment.css('b.b-user').last.inner_text
	  	  data[:opinion] = comment.css('div.b-opinions__text').collect do |commm|
			commm.inner_text+"\n" if !commm.css('p').empty?
		  end
	  	  data[:comment] = comment.css('div.b-opinions__text').collect do |commm|
			commm.inner_text+"\n" if commm.css('p').empty?
		  end
	  	  data[:rating] = comment.css('div.grade').css('span.b-rating__star-other').size
	  	  res << data
	  	end
	  end
	  res.uniq
	end

	def parse_comment(comment)
	  data = Hash.new	
	  data[:user] = comment.css('b.b-user').inner_text
	  data[:opinion] = comment.css('p.user-opinion').inner_text
	  data[:comment] = comment.css('div.data').css('p').last.inner_text if comment.css('div.data').css('p').last['class'].nil?
	  data[:rating] = comment.css('div.grade').css('span.b-rating__star-other').size
	  data
	end

	def modelid(url)
	  url[/(modelid=)\d+/][8..-1] if !url[/(modelid=)\d+/].nil?
	end




	# def write_file(hash)
	#   xml=Gyoku::Hash.to_xml(hash)
	#   filepath = 'D:\\Dropbox\\kursi\\gem\\1.xml'
	#   File.open(filepath,"w") do |data|
	#   data << xml
	#   end
	# end



# проверки

  # страница с товаром?
  def product_link?(url)
    url.to_s.include?('modelid')
  end

  # # На странице один товар?
  # def self.product?(doc)
  #   !!doc.css("h1.b-page-title")
  # end


  # # Страница бренда?
  # def self.brand?(doc)
  #   !!doc.css("div.block-header")
  # end


  # # Страница со списком товаров
  # def self.products?(doc)
  #   !!doc.css("div.b-switcher")
  # end


end
