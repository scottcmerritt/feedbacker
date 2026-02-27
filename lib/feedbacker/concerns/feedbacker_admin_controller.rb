require 'active_support/concern'

module Feedbacker
  module FeedbackerAdminController
    extend ActiveSupport::Concern

    ADMIN_USERS_PER_PAGE = 25
    
    included do
      # method to add to controller

        before_action :authenticate_admin!, except: [:updates,:first_admin,:contact_us]
        before_action :visitor_shared, only: [:visits, :visit_locations, :visit_referrers]
        protect_from_forgery except: :page_ideas
      end
  
      def first_admin
        if is_first_user? && !is_admin? && no_admins?
          current_user.add_role :admin
          redirect_to admin_users_path, notice: "You are now an admin!"
        else
          redirect_to admin_users_path
        end
      end

      def page_ideas
        @action_name = params[:action_name]
        @controller_name = params[:controller_name]

        respond_to do |format|
          format.html {  }
          format.js do 
            html = render_to_string(:partial=>"feedbacker/admin/page_ideas",:locals=>{controller_name:@controller_name,action_name:@action_name},:layout=>false)
            render json: {html: html}
          end
          #format.json { head :no_content }
        end
      end
      
      def index
        @first_impression = Impression.where(impressionable_type:"Site").order("created_at ASC").first

        @grouped_impressions = Impression.select("impressionable_type as type,COUNT(id) as views")
        .group("impressionable_type").map{|row| [row.type,row.views]} #.where(impressionable_type:"Site")
      end

      def show
        redirect_to controller: "admin", action: "index"

      end

      def analytics
        page_size = 40

        @views = Impression.select("*").order("created_at DESC")

        @listen_book_public = Impression.where(action_name:"listen",user_id:nil)
        @listen_book = Impression.where("action_name = ? AND user_id > 0","listen")

        @find_library_public = Impression.where(action_name:"find_library",user_id:nil)
        @find_library = Impression.where("action_name = ? AND user_id > 0","find_library")

        @downloads_public = Impression.where(action_name:"download_file",user_id:nil)
        @downloads = Impression.where("action_name = ? AND user_id > 0","download_file")

        unless params[:all]
          @downloads_public = @downloads_public.where("created_at > ?",30.days.ago)
          @downloads = @downloads.where("created_at > ?",30.days.ago)
        end

        @downloads_public_top = Impression.select("impressionable_id,impressionable_type,COUNT(impressionable_id) as downloads,COUNT(DISTINCT(ip_address)) as downloaders").where(action_name:"download_file",user_id:nil,impressionable_type:"Book").group(:impressionable_type,:impressionable_id).order("COUNT(impressionable_id) DESC")
        @downloads_top = Impression.select("impressionable_id,impressionable_type,COUNT(impressionable_id) as downloads,COUNT(DISTINCT(user_id)) as downloaders").where("action_name = ? AND user_id > 0 AND impressionable_type = ?","download_file","Book").group(:impressionable_type,:impressionable_id).order("COUNT(impressionable_id) DESC")

        @user_id = params[:user_id]

        @top_viewers = User.not_spam.confirmed.where(id:Impression.select("user_id").group("user_id").pluck(:user_id))

        @top_viewers = @top_viewers.sort_by{|user| -user.total_views}
        
        if @user_id == "anon"
          @views = @views.where(user_id:nil)
        elsif @user_id == "notbot"
          botname = "bot"
          @views = @views.where("user_id is NULL AND message NOT LIKE ?","%#{botname}%")
        elsif @user_id == "google"
          botname = "google"
          @views = @views.where("user_id is NULL AND message LIKE ?","%#{botname}%")
        elsif params[:search]
          @views = @views.where("user_id is NULL AND message LIKE ?","%#{params[:search]}%")
        else
          @views = @views.where(user_id:params[:user_id]) unless params[:user_id].blank?
          @views = @views.where(ip_address:params[:ip_address]) unless params[:ip_address].blank?
        end

        @views_count = @views.count
        @views = @views.page(params[:page]).per(page_size)

        range1 = 4.weeks.ago.midnight..Time.now
        range2 = 12.weeks.ago.midnight..Time.now

        @controller_usage = Impression.select("controller_name").group("controller_name")
        @controller_usage = (@user_id == "anon" ? @controller_usage.where(user_id:nil) : @controller_usage.where(user_id:params[:user_id])) if !params[:user_id].blank?

        # column_chart, line_chart, pie_chart
        @charts = [
          [Impression.where(impressionable_type:"Site").group_by_day(:created_at),"Views/day","column_chart",range1],
          [Impression.where(impressionable_type:"Site").group_by_week(:created_at),"Views/week","column_chart",range2],
          [Impression.where(impressionable_type:"Book").group_by_day(:created_at),"Book views/day","column_chart",range1],
        ]

        @charts.each_with_index do |chart,index|
          @charts[index][0] = @charts[index][0].where(user_id:params[:user_id]) if !params[:user_id].blank?
        end

        #@grouped_tags = ActsAsTaggableOn::Tag.select("name,taggings_count").map{|row| [row.name,row.taggings_count]}.sort_by{|row| -row[1]}
        #@grouped_tags_top = ActsAsTaggableOn::Tag.select("name,taggings_count").map{|row| [row.name,row.taggings_count]}.sort_by{|row| -row[1]}.first(@top)
      end


      def old_analytics
      @views = Impression.select("*").order("created_at DESC")

      @top_viewers = User.where(id:Impression.select("user_id").group("user_id").pluck(:user_id))
      @views = @views.where(user_id:params[:user_id]) unless params[:user_id].blank?
      @views = @views.page(params[:page])

      range1 = 4.weeks.ago.midnight..Time.now
      range2 = 12.weeks.ago.midnight..Time.now

      @controller_usage = Impression.select("controller_name").group("controller_name")
      @controller_usage = @controller_usage.where(user_id:params[:user_id]) if !params[:user_id].blank?

      # column_chart, line_chart, pie_chart
      @charts = [
        [Impression.where(impressionable_type:"Site").group_by_day(:created_at),"Views/day","column_chart",range1],
        [Impression.where(impressionable_type:"Site").group_by_week(:created_at),"Views/week","column_chart",range2],
        [Impression.where(impressionable_type:"Book").group_by_day(:created_at),"Book views/day","column_chart",range1],
      ]

      @charts.each_with_index do |chart,index|
        @charts[index][0] = @charts[index][0].where(user_id:params[:user_id]) if !params[:user_id].blank?
      end

      #@grouped_tags = ActsAsTaggableOn::Tag.select("name,taggings_count").map{|row| [row.name,row.taggings_count]}.sort_by{|row| -row[1]}
      #@grouped_tags_top = ActsAsTaggableOn::Tag.select("name,taggings_count").map{|row| [row.name,row.taggings_count]}.sort_by{|row| -row[1]}.first(@top)
    end

def cleanup
    per_page = 15
    @queries = ["w/out language","No tags","No files","Remote images ONLY","All (w/out pic)","PDF (w/out pic)","PDF (w/out page count)","All (w/out page count)","No filesize", "Metadata (run)"]
    @query_id = params[:query_id].to_i
    if defined?(Book)
    case @query_id
    when 0
      @books = Book.where("lang is NULL").page(params[:page])
    when 1 # no tags

      @tagged_books = Book.select("books.*,books.name,taggings.taggable_type").joins("LEFT JOIN taggings ON taggings.taggable_id = books.id")
      .where("taggings.taggable_type = ?","Book").group("books.id,books.name,taggable_type")
      @books = Book.select("books.*").where.not(id:@tagged_books.pluck(:id))
      @books = @books.page(params[:page])
    when 2 # no file, NOT hard_copy
      @books = Book.where(file:nil,hard_copy:false).page(params[:page])
    when 3 # No images #ONLY remote images (no saved thumbnail)
      @books = Book.all.each.collect{|book| book if book.remote_thumb_guess? && !book.thumbnail?}.compact
      @books = Kaminari.paginate_array(@books).page(params[:page]).per(per_page)


      #books with a local image
      @books2 = Book.all.each.collect{|book| book if book.thumbnail?}.compact
      @books2_title = "#{@books2.length} books with a local image"
    when 4 # No images #ONLY remote images (no saved thumbnail)
      @books = Book.all.each.collect{|book| book if !book.thumb_guess_sm?}.compact
      @books = Kaminari.paginate_array(@books).page(params[:page]).per(per_page)
    when 5 # PDF (w/out pic)
      @books = Book.where.not(file:nil).each.collect{|book| book if book.remote_thumb_guess.blank? && !book.thumbnail?}.compact
      @books = Kaminari.paginate_array(@books).page(params[:page]).per(per_page)
    when 6 # without page count
      @books = Book.with_file.where(hard_copy:false,page_count:nil).page(params[:page]).per(per_page)
    when 7
      @books = Book.where(page_count:nil).page(params[:page])

    when 8
      @books = Book.with_file.where(filesize:nil).page(params[:page])
    when 9
      Book.all.each do |book|
        book.update_meta_data! langs: @languages
      end
      redirect_to controller: "admin", action: "cleanup", notice: "Meta data populated using tags in BOTH languages"
    end
    end
  end

  # POST admin_contact_us_path
  def contact_us
    if params[:msg_key] == "inventory_wrong"

      message = "Inventory off for book #{params[:book_id]}"
    else
      message = room_message_params[:message]
      message+="\nbook #{params[:book_id]}" if params[:book_id]
    end
    user_id = current_user ? current_user.id : -1
    Room.admin_messages.room_messages.create(message: message,user_id:user_id)
     if is_admin? && !params[:msg_key]
      redirect_to controller: "admin", action: "messages"
    else
      flash[:notice] = "Site admins have been notified"
      if defined?(LibrariansController)
        #redirect_to controller: "librarians", action: "index", book_id: params[:book_id]
        redirect_to main_app.librarians_path(book_id:params[:book_id])
      else
        redirect_to main_app.root_path #controller: "admin", action: "messages"
      end
    end
  end

  def logins
    @admin_room = Room.admin_messages
    @spam_msgs = @admin_room.room_messages.where("message LIKE ?","Spam detected from registration:%").order("created_at DESC")
    @failed_logins = @admin_room.room_messages.where("message LIKE ?","LOGIN::FAIL%").order("created_at DESC")
  end

  def messages
    @admin_room = Room.admin_messages
    @admin_room.room_messages.where("room_messages.id = ?", params[:rmid]).first.destroy if params[:rmid] && params[:msg_remove] && is_admin?
    
    @update_msgs = @admin_room.room_messages.where("message LIKE ?","Report:: UPDATING%").order("created_at DESC")
    @add_msgs = @admin_room.room_messages.where("message LIKE ?","Report:: ADDING%").order("created_at DESC")

    @failed_logins = @admin_room.room_messages.where("message LIKE ?","LOGIN::FAIL%").order("created_at DESC")

    @spam_msgs = @admin_room.room_messages.where("message LIKE ?","Spam detected from registration:%").order("created_at DESC")

    exclude_ids = @spam_msgs.pluck(:id) + @add_msgs.pluck(:id) + @update_msgs.pluck(:id)
    @admin_msgs = @admin_room.room_messages.where.not(id:exclude_ids).order("created_at DESC")

  end

    def send_user_message
      @admin_ids = User.with_role(:admin).pluck(:id)

      @user = User.find_by(id:params[:user_id])
      @room = Room.user_messages(user_id:@user.id) unless @user.nil?
      if request.post?
        message = room_message_params[:message]

        if @user.nil?
          flash[:notice] = "You need to select a user"
        else
          Room.user_messages(user_id:@user.id).room_messages.create(message: message,user_id:current_user.id)
          current_user.favorite(@user, scope: :messaged)

          begin
            UserMailer.send_message(user:@user,sender:current_user,message: message).deliver
            flash[:notice] ="Message sent to user: #{@user.id}"
          rescue Exception => ex
            flash[:notice] ="Error delivering message to user: #{@user.id}"
          end
        end
        
        redirect_to controller:"admin", action:"send_user_message"
      else
        @hidden_fields = @user.nil? ? {} : {"user_id":@user.id}
        @messages = RoomMessage.recent.where(user_id:@admin_ids).page(params[:page])
      end
    end


    def visitor_actions
      @frame = params[:frame]

      @ip_address = params[:ip]
      @is_public = params[:is_public].blank? ? nil : ""
      @last_actions = Site.last_actions(ip:@ip_address,user_id: @is_public.blank? ? nil : "")
    end

    def visits
      @users = User.all.sort_by{|user| (user.last_view ? user.last_view : 100.days.ago)}.reverse
      @user = User.find_by(id:params[:user_id])

      wh_sql = params[:users] ? "(user_id > 0)" : "((user_id is NULL OR user_id > 0) OR ip_address is null)"
      
      @visitors = Impression.select("ip_address,COUNT(id) as view_count,MAX(user_id) as user_id,MAX(created_at) as last_visit")
      .where(wh_sql)
      .group("ip_address")
      .order("#{@sort_by} #{@sort_dir}")

      @visitors = @visitors.where("controller_name = ?",params[:controller_name]) if params[:controller_name]
      @visitors = @visitors.where("action_name = ?",params[:action_name]) if params[:action_name]

      @visitor_users = User.joins("LEFT JOIN impressions ON impressions.user_id = users.id").group("users.id")
      @visitor_users = @visitor_users.where("controller_name = ?",params[:controller_name]) if params[:controller_name]
      @visitor_users = @visitor_users.where("action_name = ?",params[:action_name]) if params[:action_name]

      @visitors = @visitors.page(params[:page]).per(@limit)
    end

    def visit_referrers
      # note, this is already set in the shared private method
      @limit = 200 if !params[:limit]

      @ignore = params[:ignore]
      @include = params[:include]

      ignore_q = "%#{@ignore}%" unless @ignore.blank?
      include_q = "%#{@include}%" unless @include.blank?

      @imessage = params[:imessage]

      @iaction = params[:action_name]
      @icontroller = params[:controller_name]

      @itype = params[:itype]
      @iid = params[:iid]

      @all_visits = params[:all_visits]

      @is_public = params[:is_public]
      @user_id = params[:user_id]


      @visitors = Impression.order("created_at DESC")
      @visitors = @visitors.where("NOT (referrer is NULL OR referrer = ?)", "") if @all_visits.blank?

      if @user_id.blank?
        @visitors = @visitors.where(user_id:nil) unless @is_public.blank?
      else
        @visitors = @visitors.where(user_id:@user_id)
      end


      @visitors = @visitors.where("NOT referrer LIKE ?",ignore_q) unless ignore_q.blank?
      @visitors = @visitors.where("referrer LIKE ?",include_q) unless include_q.blank?

      @visitors = @visitors.where(action_name:@iaction.downcase) unless @iaction.blank?
      @visitors = @visitors.where("LOWER(controller_name) = ?", @icontroller.downcase) unless @icontroller.blank?

      @visitors = @visitors.where("LOWER(impressionable_type) = ?",@itype.downcase) unless @itype.blank?
      @visitors = @visitors.where(impressionable_id: @iid) unless @iid.blank?

      @visitors = @visitors.where(message: @imessage) unless @imessage.blank?

      @visitors = @visitors.page(params[:page]).per(@limit)
    end

    def public_locations

      @country_code = params[:country_code]
      @state_code = params[:state_code]

      @is_anon = params[:is_anon]
      @is_user = params[:is_user]

      @within_days = params[:within_days] || 30


      @count_not_geocoded = Impression.select("impressions.*")
      .joins("LEFT JOIN geocode_caches ON impressions.ip_address = geocode_caches.ip_address")
      .where("(NOT geocode_caches.ip_address is NULL) AND impressions.created_at > ? AND (country is null OR country = ?)",@within_days.to_i.days.ago,"").count

      @count_all = Impression.select("impressions.*").joins("LEFT JOIN geocode_caches ON impressions.ip_address = geocode_caches.ip_address")
      .where("(NOT geocode_caches.ip_address is NULL) AND impressions.created_at > ?",@within_days.to_i.days.ago).count

      @percent_not_geocoded = 100*(@count_not_geocoded.to_f / @count_all)

      @num_countries = params[:num_countries] || 10
      @num_states = params[:num_states] || 50
      @num_cities = params[:num_cities] || 100


      @countries = GeocodeCache.select("country,COUNT(impressions.id) as total_views")
      .joins("LEFT JOIN impressions ON impressions.ip_address = geocode_caches.ip_address")
      .where("impressions.created_at > ?",@within_days.to_i.days.ago)

      @countries = @countries.where("impressions.user_id is NULL") if @is_anon && !@is_user
      @countries = @countries.where("impressions.user_id > 0") if @is_user && !@is_anon
      @countries = @countries.where("(impressions.user_id is NULL OR impressions.user_id > 0)") if @is_user && @is_anon
      @countries = @countries.group("country")

      @states = GeocodeCache.select("country,state,COUNT(impressions.id) as total_views")
      .joins("LEFT JOIN impressions ON impressions.ip_address = geocode_caches.ip_address")
      .where("country = ? AND impressions.created_at > ?",@country_code, @within_days.to_i.days.ago)
      
      @states = @states.where("impressions.user_id is NULL") if @is_anon && !@is_user
      @states = @states.where("impressions.user_id > 0") if @is_user && !@is_anon
      @states = @states.where("(impressions.user_id is NULL OR impressions.user_id > 0)") if @is_user && @is_anon
      @states = @states.group("country,state")

      @cities = GeocodeCache.select("country,state,city,COUNT(impressions.id) as total_views")
      .joins("LEFT JOIN impressions ON impressions.ip_address = geocode_caches.ip_address")
      .where("country = ? AND state = ? AND impressions.created_at > ?",@country_code,@state_code,@within_days.to_i.days.ago)
      
      @cities = @cities.where("impressions.user_id is NULL") if @is_anon && !@is_user
      @cities = @cities.where("impressions.user_id > 0") if @is_user && !@is_anon
      @cities = @cities.where("(impressions.user_id is NULL OR impressions.user_id > 0)") if @is_user && @is_anon
      @cities = @cities.group("country,state,city")

      @views_by_country = @countries.sort_by{|row| -row.total_views}
      @country_views_filtered = @views_by_country.collect{|row| [Site.country_name_from_code(row["country"]),row["total_views"]]}
      @country_views_filtered = @country_views_filtered[0...@num_countries.to_i] if @num_countries

      @views_by_state = @states.sort_by{|row| -row.total_views}
      @state_views_filtered = @views_by_state.collect{|row| [row["state"],row["total_views"]]}
      @state_views_filtered = @state_views_filtered[0...@num_states.to_i] if @num_states

      @views_by_city = @cities.sort_by{|row| -row.total_views}
      @city_views_filtered = @views_by_city.collect{|row| [(row["state"]+"/"+row["city"]),row["total_views"]]}
      @city_views_filtered = @city_views_filtered[0...@num_cities.to_i] if @num_cities


      @impressions = Impression.select("impressions.*").joins("LEFT JOIN geocode_caches ON impressions.ip_address = geocode_caches.ip_address")

      if @country_code
        @impressions = @impressions.where("country = ? AND state = ? AND impressions.created_at > ?",@country_code,@state_code,@within_days.to_i.days.ago) if @state_code
        @impressions = @impressions.where("country = ? AND impressions.created_at > ?",@country_code, @within_days.to_i.days.ago) if !@state_code
      end

      @impressions = @impressions.where("impressions.user_id is NULL") if @is_anon && !@is_user
      @impressions = @impressions.where("impressions.user_id > 0") if @is_user && !@is_anon
      @impressions = @impressions.where("(impressions.user_id is NULL OR impressions.user_id > 0)") if @is_user && @is_anon


      range_param = 60.days.ago
      @chart_data = @impressions.where("impressions.created_at >= ?",range_param).group_by_day("impressions.created_at", range: range_param.midnight..Time.now)

      @impressions = @impressions.page(params[:page])

    end

    # admin/visits/locations
    # get unique ip addresses
    def visit_locations
      @unique_ip_addresses = Impression.select("DISTINCT(ip_address)")
      @unique_user_ids = Impression.select("DISTINCT(user_id)")
      
    
      group_by = params[:groupby] == "ip" ? "ip_address" : "user_id" 

      @visitors = Impression.select("MAX(ip_address) as ip_address,COUNT(id) as view_count,MAX(user_id) as user_id,MAX(created_at) as last_visit,MIN(created_at) as first_visit,MAX(message) as msg,MAX(controller_name) as contr,MAX(action_name) as act")
      .group(group_by) #{}"ip_address,user_id")
      .order("#{@sort_by} #{@sort_dir}")
      .where("(user_id > 0 OR user_id is null)")


      @visitors = @visitors.where.not(user_id:nil) if params[:users]
      @visitors = @visitors.where(user_id:nil) if params[:anons]

      @visitors = @visitors.page(params[:page]).per(@limit)


      @chart_thresh = params[:chart_thresh] ? params[:chart_thresh].to_i : 10
      @percentages = Site.visitor_countries logger: logger
      @percentages = @percentages.delete_if{|k,v| !Site.country_code_whitelist.include?(k) && v < @chart_thresh} unless params[:all]
    end

    # another VIEW for tags (since tags are used for content lists, i.e. "reading lists")
    def lists
      do_admin_tags
      render "tags"
    end
    def list
      do_admin_tags
      render "tags"
    end

    def tags
=begin      
      @sortbys = ["count","az"]
      @sortby = @sortbys.include?(params[:sortby]) ? params[:sortby] : "az"
      @tags = ActsAsTaggableOn::Tag.all

      @tags = params[:sortby] && params[:sortby] == "count" ? @tags.order("taggings_count DESC") : @tags.order("name ASC")
      @tag = ActsAsTaggableOn::Tag.find_by(id:params[:id])

      @top = params[:top] ?  params[:top].to_i : 10

      @grouped_tags = ActsAsTaggableOn::Tag.select("name,taggings_count").map{|row| [row.name,row.taggings_count]}.sort_by{|row| -row[1]}
      @grouped_tags_top = ActsAsTaggableOn::Tag.select("name,taggings_count").map{|row| [row.name,row.taggings_count]}.sort_by{|row| -row[1]}.first(@top)
=end    

      do_admin_tags
    end

     def db
      Feedbacker::DataLog.recent.limit(10).destroy_all if params[:clear_snapshot]

      max_log_frequency = 60.minutes.ago
      Feedbacker::DataLog.mock_data if params[:mock]
      @clean_amt = params[:clean_amt] && (params[:clean_amt].to_i.to_s == params[:clean_amt]) ? params[:clean_amt].to_i : 400
      @cleaned = false

      if params[:cleandb]
        if @clean_amt > 2000
          flash[:notice] = "You can only remove 2000 rows at a time"
          @clean_amt = 2000
        else
          flash[:notice] = "#{@clean_amt} rows from the impressions table were removed"
        end
        snapshot_db!

        Impression.where(impressionable_type:"Site").order("created_at ASC").limit(@clean_amt).destroy_all
        @cleaned = true
      else
        snapshot_db! if params[:snapshot] || !Feedbacker::DataLog.where("created_at > ?", max_log_frequency).exists?
      end

      @db_info = Feedbacker::Stats.database_info
      @rows_per_table = @db_info[:rows][:per_table]
      
      if params[:history]
        @start = params[:start] && (params[:start].to_i.to_s == params[:start]) ? params[:start].to_i : 30
        
        process_table_filters
        @db_growth_data = Feedbacker::DataLog.db_rows_fmt(start:@start,table_filters:@tbls_selected)

        @history = Feedbacker::DataLog.where("domain = ? AND key = ? AND created_at >= ?","db","rows",@start.days.ago)
      end

      @archives = Feedbacker::Archive.all

      redirect_to controller: "admin", action: "db" if @cleaned
    end
    

    def old_db
        Community::Org.cache_authors!(archive: true,limit:1000) if params[:cache_authors]

        max_log_frequency = 60.minutes.ago

        Feedbacker::DataLog.mock_data if params[:mock]

        tmprow = {id:1,rows:[1,2,3,4,5]}
        @archive_row = Feedbacker::Archive.create(archive_type:"test",data:tmprow,note:"test archive row")
        @archive_row.reload

        @archives = Feedbacker::Archive.all

        if params[:cleandb]
          amt = params[:amt] ? params[:amt].to_i : 2000
          Impression.where(impressionable_type:"Site").order("created_at ASC").limit(amt).destroy_all
        end        
        @db_info = Feedbacker::Stats.database_info

        if params[:history]
          @start = params[:start] && (params[:start].to_i.to_s == params[:start]) ? params[:start].to_i : 30

          process_table_filters
          @db_growth_data = Feedbacker::DataLog.db_rows_fmt(start:@start,table_filters:@tbls_selected)

          @history = Feedbacker::DataLog.where("domain = ? AND key = ? AND created_at >= ?","db","rows",@start.days.ago)
        end  
        
        snapshot_db! if params[:snapshot] || !Feedbacker::DataLog.where("created_at > ?", max_log_frequency).exists?
        
    end

    def cache
      #@cache_misses = CacheBase.get_list_objects(Translate.cache_miss_log_key, load_objects: false, with_keys: true
      #@cache_miss_count = $redis.smembers(Translate.cache_miss_log_key).length
      @cache_miss_count = $redis.scard Feedbacker::Translate.cache_miss_log_key

      @row_limit = params[:limit] ? params[:limit].to_i : 50

      list_key = Feedbacker::Translate.cache_miss_log_key
      @exploring = Feedbacker::CacheBase.get_list_items(list_key).sample(@row_limit)

      @removed_list_items = []
      if params[:clearmisses]

        @exploring.each do |key|
          if !Feedbacker::CacheBase.exists?(key)
            Feedbacker::CacheBase.destroy_list_object!(list_key, key)
            @removed_list_items.push key
          else

            begin
              obj = Feedbacker::Cache.get_obj(key)
              if obj.kind_of?(Feedbacker::Translation)
                Feedbacker::CacheBase.destroy_list_object!(list_key, key)
                @removed_list_items.push key
              end
            rescue
              #obj = Cache.get_obj(key,nil,true)
            end

          end
        end
      end


      

      @some_rows = Feedbacker::CacheAnalyze.some_keys(max_rows:@row_limit)

      @cache_key = params[:cachekey]
      Cache.remove_key(@cache_key) if params[:removecachekey]

      if @cache_key
        begin
          @cache_obj = Feedbacker::Cache.get_obj(@cache_key)
        rescue
          @cache_obj =Feedbacker::Cache.get_obj(@cache_key,nil,true)
        end
      end

      if params[:clearcache]
        Feedbacker::CacheAnalyze.some_keys(max_rows:500).each do |k,v|
          if k.include?("translate") || k.include?("cache")

          else

            if v == -1
              obj = Feedbacker::Cache.get_obj(k)
              Feedbacker::Cache.remove_key(k) if obj.kind_of?(Translation)
            end
          end
        end
      end
    end


    def flag_spammer

      is_spam = params[:is_spam] == "0" ? false : true
      set_user
      if is_spam
        @user.update(is_spam:true,spam_flagged_at:Time.now,spam_flagged_by:current_user.id)
        flash[:notice] = "User flagged as spammer"
      else
        @user.update(is_spam:false,spam_flagged_at:Time.now,spam_flagged_by:current_user.id)
        flash[:notice] = "User unflagged as spammer"
      end

      if defined?(Room) && Room.respond_to?(:admin_messages)
        message = "User #{is_spam ? "FLAGGED" : "UNFLAGGED"} as spammer: user #{@user.id}: #{@user.email}"
        Room.admin_messages.room_messages.create(message: message,user_id:current_user.id)
      end


      redirect_to controller: "admin", action: "users"
    end


    def user_confirm
      @user = User.find(params[:id])
      @user.update(confirmed_at:Time.now.utc)
    #   @user.confirm # this doesn't work if they confirmation period expired
      #@user.save
      redirect_to controller: "admin", action: "users", errors: @user.errors.full_messages.to_s
    end

    def users
      @role = params[:role]
      manually_confirm_user! if params[:confirm_user]

      if params[:spammers]
        users = User.spam
      else
        if params[:active]
          minutes_ago = params[:mins_ago] ? params[:mins_ago].to_i : 60 * 24
          @active = User.active_users(minutes_ago: minutes_ago)
          @active = @active.confirmed.not_demo if params[:confirmed]
          @active = @active.not_confirmed if params[:not_confirmed]
          users = @active
        else
          users = User.not_spam
        end
      end
      users = users.confirmed if params[:confirmed]
      users = users.not_confirmed if params[:not_confirmed]
      users = users.is_demo if params[:is_demo]
      users = users.not_demo if params[:no_demo]

      order_sql = if ActiveRecord::Base.connection.adapter_name.match?(/postgres/i)
        "last_sign_in_at DESC NULLS LAST"
      else
        "last_sign_in_at DESC"
      end
      users = users.order(order_sql)

      @users = @site_roles.include?(@role) ? users.with_role(@role.to_sym) : users

      if params[:q].present?
        @q = params[:q].to_s.strip
        q = "%#{@q.downcase}%"
        if ActiveRecord::Base.connection.adapter_name.match?(/postgres/i)
          @users = @users.where("email ILIKE ? OR public_name ILIKE ? OR first_name ILIKE ? OR last_name ILIKE ?", q, q, q, q)
        else
          @users = @users.where("LOWER(email) LIKE ? OR LOWER(public_name) LIKE ? OR LOWER(first_name) LIKE ? OR LOWER(last_name) LIKE ?", q, q, q, q)
        end
      end

      if @users.is_a?(Array)
        @users = Kaminari.paginate_array(@users)
      else
        @users = @users.includes(:roles) if User.reflect_on_association(:roles)
      end
      @users = @users.page(params[:page]).per(Feedbacker::FeedbackerAdminController::ADMIN_USERS_PER_PAGE)

      load_admin_user_counts

      render "feedbacker/admin/users", layout: true
    end

      def modify_role
        @user = User.find_by(id: params[:user_id])
        
        if @site_roles.include?(params[:role])
          if params[:act] == "add"
            @user.add_role params[:role].to_sym
          elsif params[:act] == "del"
            @user.remove_role params[:role].to_sym
          end
        elsif params[:role] == "is_demo"
          @user.update(is_demo:true) if params[:act] == "add"
          @user.update(is_demo:false) if params[:act] == "del"
          flash[:notice] = params[:act] == "add" ? "User #{@user.id} was converted to a demo account" : "User #{@user.id} is no longer a demo account"
        end

        redirect_to controller: "admin", action: "users", user_id: @user.id
      end

      def fake_add
        100.times.each do 
          Book.create name: Faker::Movie.title
        end
      end


      def fake_clear
        Book.demo_data.destroy_all if params[:books].to_s == "true"
      end

      def updates

        @updates = load_updates
        @posts = Post.all.page(params[:page]).per(10)

      end

      def html_sandbox
        @tight_layout = true
        @hide_footer = true

        #require 'diffy'
        @diffed = Diffy::Diff.new("prev title OLD", "current title",:include_diff_info=>false).to_s(:html)
        @translate = Feedbacker::Translate.find_by(id:params[:translate_id])
      end

      # receives two texts via post AND returns the diff
      def html_diff
        
        @diffed = Diffy::Diff.new(params[:t1], params[:t2],:include_diff_info=>false).to_s(:html)

        diffed_text = @diffed
        render json: {html:diffed_text}
      end

      private

      def visitor_shared
        @limit = params[:limit] ? params[:limit].to_i : 10
        @limit = 100 if @limit < 1
        @limit = 2000 if @limit > 2000

        @sort_bys = ["last_visit","view_count"]
        @sort_dir = "DESC"
        @sort_by = @sort_bys[params[:sb].to_i]
      end

      def room_message_params
        params.require(:room_message).permit(:message)
      end

      def set_user
        @user = User.find_by(id:params[:id])
      end
      
        
      def process_table_filters
        @tbls_all = @db_info[:tables][:names] - @db_info[:tables][:hidden]
        @tbls_selected = []
        @tbls = params[:tbls] ? params[:tbls].to_a : nil
        return nil if @tbls.nil?
              
        @tbls.each do |tbl|
          @tbls_selected.push tbl if @tbls_all.include?(tbl)
        end
        @tbls_selected
      end

      def do_admin_tags
        @q = params[:q]
        @sortbys = ["count","az"]
        @sortby = @sortbys.include?(params[:sortby]) ? params[:sortby] : "az"
        
        @selected_tag = Tag.find_by(id:params[:tag_id])

        @parent_tags = Tag.most_used_tags otype:"Tag"

        if @q.nil?
          if params[:sortby] && params[:sortby] == "count" 
            @tags = @selected_tag.nil? ? ActsAsTaggableOn::Tag.all : ActsAsTaggableOn::Tag.tagged_with([@selected_tag])
            @tags = @tags.order("taggings_count DESC")# ?   : @tags.order("name ASC")
          else
            @tags = Tag.all_tags otype: nil, translated: (@sortby == "az"), tagged_with: @selected_tag, scope: params[:ttype] # ActsAsTaggableOn::Tag.all
          end
        else
          @tags = Tag.search(q: @q, langs: @languages, otype: nil).uniq
        end
        @tag = ActsAsTaggableOn::Tag.find_by(id:params[:id])

        # it is easier to use our own model (to make tags Taggable)
        @taggable_tag = Tag.find(@tag.id) unless @tag.nil?

        @top = params[:top] ?  params[:top].to_i : 10

        @grouped_tags = ActsAsTaggableOn::Tag.select("name,taggings_count").map{|row| [row.name,row.taggings_count]}.sort_by{|row| -row[1]}
        @grouped_tags_top = ActsAsTaggableOn::Tag.select("name,taggings_count").map{|row| [row.name,row.taggings_count]}.sort_by{|row| -row[1]}.first(@top)
      end

      def manually_confirm_user!
        @user = User.find_by(id:params[:confirm_user])
        @user.confirm if !@user.nil? && @user.confirmed_at.nil?
      end

      def load_admin_user_counts
        cache_key = "feedbacker/admin_users_counts"
        cached = Rails.cache.read(cache_key)
        if cached
          @admin_user_count_all = cached[:all]
          @admin_user_count_not_spam = cached[:not_spam]
          @admin_user_count_spam = cached[:spam]
          @admin_user_count_confirmed = cached[:confirmed]
          @admin_user_count_not_confirmed = cached[:not_confirmed]
          @admin_user_count_not_confirmed_not_demo = cached[:not_confirmed_not_demo]
          @admin_user_count_confirmed_not_spam_not_demo = cached[:confirmed_not_spam_not_demo]
          @admin_user_count_is_demo = cached[:is_demo]
          @admin_user_count_removed = cached[:removed]
          @admin_user_count_by_role = cached[:by_role] || {}
        else
          @admin_user_count_all = User.count
          @admin_user_count_not_spam = User.not_spam.count
          @admin_user_count_spam = User.spam.count
          @admin_user_count_confirmed = User.confirmed.count
          @admin_user_count_not_confirmed = User.not_confirmed.count
          not_spam = User.not_spam
          @admin_user_count_not_confirmed_not_demo = not_spam.not_confirmed.not_demo.count
          @admin_user_count_confirmed_not_spam_not_demo = not_spam.confirmed.not_demo.count
          @admin_user_count_is_demo = User.is_demo.count
          @admin_user_count_removed = User.where(removed: true).count
          @admin_user_count_by_role = {}
          @site_roles.each do |role_name|
            @admin_user_count_by_role[role_name] = User.with_role(role_name.to_sym).count
          end
          Rails.cache.write(cache_key, {
            all: @admin_user_count_all,
            not_spam: @admin_user_count_not_spam,
            spam: @admin_user_count_spam,
            confirmed: @admin_user_count_confirmed,
            not_confirmed: @admin_user_count_not_confirmed,
            not_confirmed_not_demo: @admin_user_count_not_confirmed_not_demo,
            confirmed_not_spam_not_demo: @admin_user_count_confirmed_not_spam_not_demo,
            is_demo: @admin_user_count_is_demo,
            removed: @admin_user_count_removed,
            by_role: @admin_user_count_by_role
          }, expires_in: 30.seconds)
        end
      end
      
      def load_updates
        res = [
          {
            date: "June 21, 2021",
            posts: [
              {info: "Added CHARTS to the admin section"},
              {info: "Added user permissions, user roles (admins, moderators, etc...)"},
              {info: "and suggested books feature based on a Recommendation Engine (still being implemented)"},
              {info: "Updated the homepage"},
              {info: "Added the fields AUTHOR and LANGUAGE to the Add new Book form"}
            ]
          },
          {
            date: "June 20, 2021",
            info: "Updated the UI of the book page, project page & editing pages"
          },
          {
            date: "June 19, 2021",
            info: "Continued to upgrade the crowdfunding functionality...adapting selfstarter.us to be more flexible."
          },
          {
            date: "June 18, 2021",
            info: "Created the idea of fundable projects."
          },
          {
            date: "June 14, 2021",
            posts: [
              {info: "Added the ability to filter books by those with ACTUAL files. Hid download link if file has not yet been uploaded. Added an upload section to viewing a file (these will be role protected soon)"},
              {info: "Added view counts for books"},
              {info: "Added the ability to create accounts, login, and manage files (only if logged in)"},
              {info: "Added a swahili language file for basic site operation"}

            ]
            
          },
          {
            date: "June 13, 2021",
            info: "Added icons. Fixed a bug preventing multiple languages."
          },
          {
            date: "June 12, 2021",
            info: "Setup the site. Added a database, a book file upload tool, searching, paging, basic admin tools."
          }

        ]
      end




    def snapshot_db!      
      # causes errors: ["active_storage_variant_records","active_storage_blobs","active_storage_attachments"]
      excluded_tbl_names = ["active_storage_variant_records","active_storage_blobs","active_storage_attachments","ar_internal_metadata"]
      #permitted_tbl_names = ["users","impressions","books"] #{}","["impressions", "books", "taggings", "schema_migrations", "photos", "orders", "translates", "translate_keys", "tags", "data_logs", "settings", "comments", "payment_options", "users_roles", "room_messages", "book_checkouts", "roles", "projects", "posts", "users", "action_text_rich_texts", "sites", "site_settings","ar_internal_metadata", "rooms","room_users"] # ,  #, "active_storage_blobs", "active_storage_attachments"]
      #permitted_tbl_names = ["source_topics", "items", "votes", "sources", "item_interests", "source_authors", "import_sources", "authors", "vote_caches", "orgs", "impressions", "guess_scopes", "source_groups", "archives", "summaries", "summary_sources", "contents", "friendships", "data_logs", "schema_migrations", "imports", "versions", "users", "user_audits", "translates", "favorites", "translate_keys", "comments", "users_roles", "roles", "posts", "ar_internal_metadata", "org_users", "taggings", "summary_logs", "source_topics_removed", "commontator_comments", "commontator_threads", "commontator_subscriptions", "summary_items", "summary_items_removed", "author_orgs", "vote_audits", "source_opinions", "opinions", "content_topics", "settings", "sites", "tags"].sample(4)
      
      begin
        @rows_per_table = Feedbacker::Stats.database_info[:rows][:per_table]

        safe_rows = []
        cnt = 0
        all_tables = []
        current_table = nil
        if true
          @rows_per_table.each do |row|

            if true # && (rand(10) > 8)
            current_table = row["table"]
            all_tables.push current_table
            val = {"table":row["table"].to_s,"count":row["count"].to_i} #.as_json
            safe_rows.push(val) unless excluded_tbl_names.include?(row["table"]) # || (permitted_tbl_names.length > 0 && !permitted_tbl_names.include?(row["table"])) #unless row["table"].blank? || row["count"].nil?
            end

  #           
          # safe_rows.push({:table=> row["table"], :count => row["count"].to_i}) unless row["count"].nil? || row["table"].blank?
          end
        else
          safe_rows = []
          #safe_rows = [{"table": "posts","count":1000},{"table": "impressions","count":1000}]
          safe_rows.push({"table": "posts","count":4000})
          safe_rows.push({"table": "impressions","count":10000})
        end

        #marshaled = Marshal.dump(@rows_per_table.to_json.to_s.force_encoding('iso8859-1').encode('utf-8'))
        #marshaled = Marshal.dump(@rows_per_table).force_encoding(Encoding::UTF_8) #.encode(Encoding::UTF_8) #.gsub("\u0000", '') #.to_json)

#        json_rows = JSON.parse(safe_rows.to_json)
#        marshaled = Marshal.dump(json_rows) #.gsub("\u0000", '')

        json_rows = safe_rows.to_json.to_s
        marshaled = json_rows 
        


        #marshaled = Marshal.dump(safe_rows.to_json)
        logger.debug "SAFE_ROWS"
        logger.debug safe_rows
        #marshaled = Marshal.dump(@rows_per_table.to_json) #.force_encoding(Encoding::UTF_8)
        #marshaled = ActiveRecord::Base.connection.escape_bytea(marshaled)

        #marshaled = Marshal.dump(@rows_per_table.to_json).force_encoding('UTF-8') #.encode('utf-8')

        #marshaled = Marshal.dump(@rows_per_table.to_json)
        
        snapshot = Feedbacker::DataLog.create(note:"cleaning db",created_by:current_user.id,domain:"db",key:"rows", value: marshaled)
        @errors = [] if @errors.nil?
        @errors.push snapshot.errors.full_messages.to_s
        @errors.push all_tables
        #@errors.push "PERMITTED"
        #@errors.push permitted_tbl_names.to_s

        flash[:notice] = "Snapshot created"
        @errors.push "ROWS"
        @errors.push json_rows

      rescue Exception => ex
        flash[:notice] = "Error creating snapshot"
        @errors = [] if @errors.nil?
        @errors.push "Snapshot_db error: #{ex}"
        @errors.push "Current table: #{current_table}"
        @errors.push "All tables: #{all_tables}"
        #@errors.push "PERMITTED"
        #@errors.push permitted_tbl_names.to_s
        @errors.push "ROWS"
        @errors.push json_rows
      end
    end

      def old_snapshot_db!

            begin
              json_obj = (@db_info[:rows][:per_table]).to_json
              data_dump = Marshal.dump(json_obj)
              encoded = ActiveRecord::Base.connection.escape_bytea(data_dump)
              #data_dump = data_dump.force_encoding('iso8859-1').encode('utf-8')
            rescue Exception => ex
              logger.debug "ERROR::: add setting up DataLog: #{ex}"
            end

            begin
              Feedbacker::DataLog.create(note:"checking db",created_by:current_user.id,domain:"db",key:"rows", value: encoded) unless encoded.nil?
            rescue Exception => ex
              logger.debug "ERROR::: adding DataLog: #{ex}"
            end
      end




    module ClassMethods


    end


  end
end
