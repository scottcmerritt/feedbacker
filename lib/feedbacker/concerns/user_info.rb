module Feedbacker
  module UserInfo
    extend ActiveSupport::Concern

    # this is a method thats called when you include the module in a class.
    def self.included(base)
      base.extend ClassMethods

      # was klass
      base.instance_eval do
        #scope :ordered_for_display, order("#{self.to_s.tableize}.rank asc")
        scope :spam, -> { where("(removed = ? AND is_spam = ?)",false,true) }
        scope :not_spam, -> { where("(removed = ? AND (is_spam is null OR is_spam = ?) )",false,false) }
        scope :confirmed, -> { where("(NOT confirmed_at is null)")}
        scope :not_confirmed, -> { where("(confirmed_at is null)")}
        scope :is_demo, -> {where("is_demo =?",true)}
        scope :not_demo, -> {where("(is_demo =? OR is_demo is null)",false)}
      end
    end

=begin
     included do
      # to get table name, do self.to_s.tableize
      #scope :ordered_for_display, -> { order("#{self.to_s.tableize}.rank asc") }

      scope :spam, -> { where("(removed = ? AND is_spam = ?)",false,true) }
      scope :not_spam, -> { where("(removed = ? AND (is_spam is null OR is_spam = ?) )",false,false) }
      scope :confirmed, -> { where("(NOT confirmed_at is null)")}
      scope :not_confirmed, -> { where("(confirmed_at is null)")}
    end
=end    


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

    def is_bot?
      bot_q = "#{"bot:"}%"
      bot2_q = "%#{"bot:"}%"
      self.my_impressions.where("LOWER(message) LIKE ? OR LOWER(message) LIKE ?",bot_q, bot2_q).exists?
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

  def my_impressions
    Impression.select("*").where("user_id = ?",self.id).order("created_at DESC")
  end
  def my_referrers
    Impression.select("referrer,MAX(created_at) as created_at").group("referrer").where("user_id = ?",self.id)
  end



  def default_ip_address
    if Rails.env.production?
      self.current_sign_in_ip
    else
       "45.49.250.55" # pacific palisades, CA self.current_sign_in_ip
    end
  end

  # caches the ip address geocoded, saves unknwon if it doesn't work
  def location_cache! ip: default_ip_address, cache_duration: 10000
    val = Site.geocode(ip: ip)
    val = "unknown" if val.nil?
    Feedbacker::Cache.set_obj(Site.location_cache_key(ip:ip),val,nil,cache_duration)
    val
  end

  def location_cached ip: default_ip_address
    val = Feedbacker::Cache.get_obj(Site.location_cache_key(ip:ip))
    return location_cache!(ip: ip) if val.nil?
    val
  end

  def location_guess
    Geokit::Geocoders::MultiGeocoder.geocode(self.current_sign_in_ip) unless self.current_sign_in_ip.blank?
  end
    
  
  # for including static methods
  module ClassMethods
    def order_by_ids(ids)
      t = User.arel_table
      condition = Arel::Nodes::Case.new(t[:id])
      ids.each_with_index do |id, index|
        condition.when(id).then(index)
      end
      order(condition)
    end

    def active_users minutes_ago: 60
      user_list = User.not_spam.each.collect{|user| user if user.online? || (user.last_activity > minutes_ago.minutes.ago) }.compact.sort_by{|user| user.last_activity}.reverse
      ids = user_list.pluck(:id)
      User.where(id: ids).order_by_ids(ids)
    end
  end


  end
end