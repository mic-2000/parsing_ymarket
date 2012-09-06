require 'spec_helper'

describe Parsing do
	context "Search product by name" do
	  samsung = Parsing.new
	  samsung.find('Samsung Galaxy Pocket S5300')

		it "should return the first matching product" do
			samsung.product.should_not be_nil
		end
		it "should return correct product name" do
			samsung.product.name.should == "Samsung Galaxy Pocket S5300"
		end
		it "should return array of product characteristics" do
			samsung.product.characteristics.class.should == Array
			samsung.product.characteristics.size.should > 0
		end
		it "should return array of product comments" do
			samsung.product.comments.class.should == Array
			samsung.product.comments.size.should > 0
		end
		it "should return the name of the first commentator of product" do
			samsung.product.comments.first.user.should_not be_nil
		end
	end
	context "Parsing of products by guru filter" do
	  url='http://market.yandex.ua/guru.xml?CMD=-RR=9,0,0,0-PF=2139571715~TR~sel~select-PF=1801946~EQ~sel~1871127-VIS=70-CAT_ID=432460-EXC=1-PG=10&hid=91013'
	  parsing = Parsing.new
	  parsing.url_filter(url)

	  it "should return array of products" do
	  	parsing.products.class.should == Array
	  	parsing.products.first.class.should == ParsingYmarket::Parsing::Product
	  end

	end
end