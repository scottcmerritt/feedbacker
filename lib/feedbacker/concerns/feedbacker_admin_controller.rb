require 'active_support/concern'

module Feedbacker
  module FeedbackerAdminController
    extend ActiveSupport::Concern
    
    included do
      # method to add to controller

        before_action :authenticate_admin!, except: [:updates,:first_admin]
  
      end
  
      def first_admin
        if is_first_user? && !is_admin? && no_admins?
          current_user.add_role :admin
          redirect_to admin_users_path, notice: "You are now an admin!"
        else
          redirect_to admin_users_path
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

      @queries = ["w/out language","No tags","No files","No images"]
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
        when 2
          @books = Book.where(file:nil,hard_copy:false).page(params[:page])
        when 3
          @books = Book.all.each.collect{|book| book if !book.thumb_guess_sm?}.compact
          @books = Kaminari.paginate_array(@books).page(params[:page]).per(10)
        end

      end

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
          @tags = Tag.all_tags otype: nil, translated: (@sortby == "az"), tagged_with: @selected_tag # ActsAsTaggableOn::Tag.all
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
      set_user
    @user.update(is_spam:true,spam_flagged_at:Time.now,spam_flagged_by:current_user.id)
    flash[:notice] = "User flagged as spammer"
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
        #@role = params[:role]
        #manually_confirm_user! if params[:confirm_user]

        #@user = User.find_by(id: params[:user_id]) unless params[:user_id].nil?
        
        #@users = @site_roles.include?(@role) ? User.with_role(@role.to_sym) : User.all

        #@users = @users.order(:confirmed_at).page(params[:page]).per(20)
      
      @role = params[:role]
      manually_confirm_user! if params[:confirm_user]

      #@user = User.find_by(id: params[:user_id]) unless params[:user_id].nil?
      
      if params[:spammers]
        users = User.spam
      else
        minutes_ago = params[:mins_ago] ? params[:mins_ago].to_i : 60*24
        @active = User.active_users(minutes_ago:minutes_ago)
        @active = @active.confirmed if params[:confirmed]
        @active = @active.not_confirmed if params[:not_confirmed]
        users = params[:active] ? @active : User.not_spam
      end
      users = users.confirmed if params[:confirmed]
      users = users.not_confirmed if params[:not_confirmed]

      users = users.order("last_sign_in_at DESC") #created_at"

      @users = @site_roles.include?(@role) ? users.with_role(@role.to_sym) : users

      if @users.kind_of? Array
        @users = Kaminari.paginate_array(@users) #.page(params[:page])
      else
        @users = @users.order(:last_sign_in_at) #:confirmed_at)) #.per(20)
      end
      @users = @users.page(params[:page])

    end

      def modify_role
        @user = User.find_by(id: params[:user_id])
        
        
        if @site_roles.include?(params[:role])
          if params[:act] == "add"
            @user.add_role params[:role].to_sym
          elsif params[:act] == "del"
            @user.remove_role params[:role].to_sym
          end
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

      private

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


      def manually_confirm_user!
        @user = User.find_by(id:params[:confirm_user])
        @user.confirm if !@user.nil? && @user.confirmed_at.nil?
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
      excluded_tbl_names = ["active_storage_variant_records","active_storage_blobs","active_storage_attachments"]
      #permitted_tbl_names = ["impressions", "books", "taggings", "schema_migrations", "photos", "orders", "translates", "translate_keys", "tags", "data_logs", "settings", "comments", "payment_options", "users_roles", "room_messages", "book_checkouts", "roles", "projects", "posts", "users", "action_text_rich_texts", "sites", "site_settings","ar_internal_metadata", "rooms","room_users"] # ,  #, "active_storage_blobs", "active_storage_attachments"]

      begin
        @rows_per_table = Feedbacker::Stats.database_info[:rows][:per_table]

        safe_rows = []
        cnt = 0
        if true
          @rows_per_table.each do |row|
            val = {"table": "#{row["table"]}","count":row["count"].to_i} #.as_json
            safe_rows.push(val) unless excluded_tbl_names.include?(row["table"]) # permitted_tbl_names.include?(row["table"]) #unless row["table"].blank? || row["count"].nil?
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
        marshaled = Marshal.dump(safe_rows.to_json) #.gsub("\u0000", '')

        #marshaled = Marshal.dump(safe_rows.to_json)
        logger.debug "SAFE_ROWS"
        logger.debug safe_rows
        #marshaled = Marshal.dump(@rows_per_table.to_json) #.force_encoding(Encoding::UTF_8)
        #marshaled = ActiveRecord::Base.connection.escape_bytea(marshaled)

        #marshaled = Marshal.dump(@rows_per_table.to_json).force_encoding('UTF-8') #.encode('utf-8')

        #marshaled = Marshal.dump(@rows_per_table.to_json)
        
        Feedbacker::DataLog.create(note:"cleaning db",created_by:current_user.id,domain:"db",key:"rows", value: marshaled)
      rescue Exception => ex
        @errors = [] if @errors.nil?
        @errors.push "Snapshot_db error: #{ex}"
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
