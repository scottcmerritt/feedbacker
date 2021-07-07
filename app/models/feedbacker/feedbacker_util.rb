module Feedbacker
	module FeedbackerUtil

	extend ActiveSupport::Concern

   	# this is a method thats called when you include the module in a class.
	  def self.included(base)
	    base.extend ClassMethods
	  end

	  # https://stackoverflow.com/questions/4099409/ruby-how-to-chain-multiple-method-calls-together-with-send
	  # for sending a dynamic of commands
	  #def send_chain(arr)
	  #  arr.inject(self) {|o, a| o.send(a) }
	  #end

	  # more robust approach (with args)
	  # arr = [:to_i, [:+, 4], :to_s, [:*, 3]]
	  # '1'.send_chain(arr) # => "555"
	def send_chain(arr)
		Array(arr).inject(self) { |o, a| o.send(*a) }
	end

	


	  module ClassMethods
	    # accesed by Post.flags, Post.flagged_spam, etc...

	    def default_spam_flags #self.flags
	      {1 => "spam", 2=> "obscene", 3=> "harassment",0 => "ok"}
	    end

	    def popular
	    	tn = self.table_name
	    	mn = tn.singularize.capitalize

			select("#{tn}.*,COUNT(comments.id) as comment_count").joins("LEFT JOIN comments ON comments.commentable_id = #{tn}.id")
		    .where("comments.commentable_type=?",mn).group("#{tn}.id")
		    .order("comment_count DESC")
		end

		# default within 0.5 day
		def active within: (0.5*24*60).to_i
			tn = self.table_name
	    	mn = tn.singularize.capitalize

			select("#{tn}.*,COUNT(comments.id) as comment_count").joins("LEFT JOIN comments ON comments.commentable_id = #{tn}.id")
			.where("comments.commentable_type=?",mn)
			.where("comments.created_at > ?",within.minutes.ago)
			.group("#{tn}.id")
			.order("comment_count DESC")

		end

	  end



	end
end