require 'spec_helper'

describe ParsingYmarket do 
	context "#name" do
		it "should return gem name" do
			ParsingYmarket.name == "parsing_ymarket"
		end
	end
end
