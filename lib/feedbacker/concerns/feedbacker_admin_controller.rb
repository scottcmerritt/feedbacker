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

    def tags
      @sortbys = ["count","az"]
      @sortby = @sortbys.include?(params[:sortby]) ? params[:sortby] : "az"
      @tags = ActsAsTaggableOn::Tag.all

      @tags = params[:sortby] && params[:sortby] == "count" ? @tags.order("taggings_count DESC") : @tags.order("name ASC")
      @tag = ActsAsTaggableOn::Tag.find_by(id:params[:id])

      @top = params[:top] ?  params[:top].to_i : 10

      @grouped_tags = ActsAsTaggableOn::Tag.select("name,taggings_count").map{|row| [row.name,row.taggings_count]}.sort_by{|row| -row[1]}
      @grouped_tags_top = ActsAsTaggableOn::Tag.select("name,taggings_count").map{|row| [row.name,row.taggings_count]}.sort_by{|row| -row[1]}.first(@top)
    end


    def db
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

        #@user = User.find_by(id: params[:user_id]) unless params[:user_id].nil?
        
        @users = @site_roles.include?(@role) ? User.with_role(@role.to_sym) : User.all

        @users = @users.order(:confirmed_at).page(params[:page]).per(20)
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
