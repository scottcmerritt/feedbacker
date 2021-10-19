module Feedbacker
  module UserInfo
    extend ActiveSupport::Concern


    def display_name_default
      "User #{self.id}"
    end
    def display_name_public
      res = self.settings(:prefs).is_public ? self.settings(:profile).full_name : display_name_default
      res.blank? ? display_name_default : res
    end

    # NOTE: this gets overriden by Community::UserCommunity
    def online?
      self.online_via_impression?
    end



# impression based data
    def online_via_impression?
      Impression.where("user_id = ? AND created_at > ?",self.id,10.minutes.ago).exists?
    end

    def total_views
      Impression.where("user_id = ?",self.id).count
    end
    def last_view
      Impression.where("user_id = ?",self.id).order("created_at DESC").first.created_at unless Impression.where("user_id = ?",self.id).order("created_at DESC").first.nil?
    end
    
    def last_activity
      [self.last_view,self.current_sign_in_at,self.last_sign_in_at,self.created_at,self.updated_at].compact.max
  #    (!user.current_sign_in_at.nil? && (user.current_sign_in_at > minutes_ago.minutes.ago)) || (!user.last_sign_in_at.nil? && (user.last_sign_in_at > minutes_ago.minutes.ago) )

    end


  end
end