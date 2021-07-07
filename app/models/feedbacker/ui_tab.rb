module Feedbacker
	class UiTab #= Struct.new(:name, :url, :links,:action,:controller) do
			def initialize(options) #name,url,links=nil,action=nil,controller=nil,id=nil,content=nil)
				@id = options[:id]
				@key = options[:key]

				@name = options[:name]
				@count = options[:count]
				@url = options[:url]
				@content = options[:content]

				@links = options[:links]
				@action = options[:action]
				@controller = options[:controller]
				
				@is_parent = options[:is_parent] || false

			end
			attr_accessor :name, :count, :url, :links, :action, :controller, :id, :content, :is_parent

			def tab_key
				"#{@key}#{@id}"
			end
			def active? link_action:nil, link_controller:nil
				return true if self.is_parent && (self.controller == link_controller)
				return true if self.action == link_action && self.controller == link_controller
			end
	end
end