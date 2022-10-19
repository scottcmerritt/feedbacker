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

	  def recipient_ids
	  	user_ids = self.commenter_ids
	  	user_ids = (user_ids + self.owner_ids).uniq.compact if self.respond_to?(:owner_ids)
	  	user_ids = (user_ids + self.interested_ids).uniq.compact if self.respond_to?(:interested_ids)
	  	user_ids
	  end


	  # announces engagement to the creator
	  def announce_engage! sender:, engage_key: "like"
	  	user_id = self.respond_to?(:createdby) ? self.createdby : (self.respond_to?(:created_by) ? self.created_by : self.user_id)
	  	user = User.find_by(id: user_id)
	  	user.announce_engage!(resource:self,sender:sender,engage_key: engage_key) unless user.nil?
	  end


	  # announces a comment ABOUT something
	  def announce_comment! sender:nil, comment: nil
        self.recipient_ids.each do |user_id|
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