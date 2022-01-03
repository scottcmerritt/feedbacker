module Feedbacker
	module FeedbackerCommentUtil

	extend ActiveSupport::Concern

   	# this is a method thats called when you include the module in a class.
	  def self.included(base)
	    base.extend ClassMethods
	  end

	  def commenter_ids
	  	ids = []
	  	self.root_comments.each do |comment|
	  		ids.push comment.user_id
	  		ids = ids + comment.children.collect{|reply| reply.user_id}
	  	end
	  	ids.uniq.compact
	  end

	  # announces a comment ABOUT something
	  def announce_comment! sender:nil, comment: nil
        self.commenter_ids.each do |user_id|
        	if sender.nil? || (sender.id != user_id)
	          user = User.find_by(id:user_id)
	          user.announce_comment!(resource:self,sender:sender,comment:nil) unless user.nil?
	      	end
        end
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