module Feedbacker
	class MenuLink
		def initialize(name,details:nil,url:nil,links:nil,action:nil,controller:nil,id:nil,content:nil)
			@name, @details, @url, @links, @action, @controller, @id, @content = name,details,url,links,action,controller, id, content
		end
		attr_accessor :name, :url, :links, :action, :controller, :id, :content, :details
	end
end