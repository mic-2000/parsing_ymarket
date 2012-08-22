require 'spec_helper'

describe Parsing_Ymarket do

	context "Parsing" do 
		# context "#name" do
		# 	it "should return gem name" do
		# 		ParsingYmarket.name == "parsing_ymarket"
		# 	end
		# end
	end

#
describe "Product" do

	it "should ruturn ArgumentError unless argument" do
		expect { Product.new }.to raise_error(ArgumentError)
	end

	it "should ruturn 'incorect url' if not model-spec page" do
		url='http://market.yandex.ua/model.xml'
		expect { Product.new(url) }.to raise_error('incorrect url')
	end

	it "should return not empty array" do
		url='http://market.yandex.ua/model.xml?CMD=-RR=9,0,0,0-PF=1801946~EQ~sel~1871127-PF=2142398356~EQ~sel~316113815-PF=1801946~EQ~sel~1871127-PF=2142398356~EQ~sel~316113815-VIS=70-CAT_ID=432460-EXC=1-PG=10&modelid=7153786&hid=91013'

		obj.name.should_not be_empty
	end


end

	context "Comment" do

		it "should return ArgumentError if not argument" do
			expect { Comment.new }.to raise_error(ArgumentError)
		end

		it "should return ArgumentError if argument not 'Nokogiri::XML::Element'" do
			expect { Comment.new("url") }.to raise_error(ArgumentError)
		end

		before do 			
			data = open('./html/comments.htm')
		  doc = Nokogiri::XML(data)
			@comment = Comment.new(doc.css('div.b-grade').first)
		end

		it "user not be nil" do
			@comment.user.should_not be_nil
		end



	end

end