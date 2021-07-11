require 'active_support/concern'

module Feedbacker
  module FeedbackerPostsController
    extend ActiveSupport::Concern
    
    included do
      # method to add to controller

        before_action :set_post, only: %i[ show edit update destroy ]
        before_action :load_posts_tabs, :load_posts_links
  
      end

  
      # GET /posts or /posts.json
      def index
        @posts = Post.all
      end
      def popular
        @page_title = "Popular"
        @posts = Post.popular

        render "index"
      end

      # similar to popular, but filter created_at > 10.days.ago
      def active
        @page_title = "Active"

        @ui = Feedbacker::Ui.new params: params
        @posts = Post.active within: @ui.filter[:within][:mins].to_i

        render "index"
      end

      # GET /posts/1 or /posts/1.json
      def show
        @new_comment    = Comment.build_from(@post, current_user.id, "")

      end

      # GET /posts/new
      def new
        @post = Post.new
      end

      # GET /posts/1/edit
      def edit
      end

      # POST /posts or /posts.json
      def create
        @post = Post.new(post_params.merge({user_id:current_user.id}))

        respond_to do |format|
          if @post.save
            format.html { redirect_to @post, notice: "Post was successfully created." }
            format.json { render :show, status: :created, location: @post }
          else
            format.html { render :new, status: :unprocessable_entity }
            format.json { render json: @post.errors, status: :unprocessable_entity }
          end
        end
      end

      # PATCH/PUT /posts/1 or /posts/1.json
      def update
        respond_to do |format|
          if @post.update(post_params)
            format.html { redirect_to @post, notice: "Post was successfully updated." }
            format.json { render :show, status: :ok, location: @post }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.json { render json: @post.errors, status: :unprocessable_entity }
          end
        end
      end

      # DELETE /posts/1 or /posts/1.json
      def destroy
        @post.destroy
        respond_to do |format|
          format.html { redirect_to posts_url, notice: "Post was successfully destroyed." }
          format.json { head :no_content }
        end
      end


      private

          # Use callbacks to share common setup or constraints between actions.
      def set_post
        @post = Post.find(params[:id])
      end

      # Only allow a list of trusted parameters through.
      def post_params
        params.require(:post).permit(:user_id, :title, :details)
      end

      def load_posts_links
        @page_links = []
        tab_key = "pageMenu"

        @page_links.push(Feedbacker::UiTab.new(
          {id:1, key: tab_key,name:"All posts",url: posts_path,controller:"posts",action:"index"}
          ))
        @page_links.push(Feedbacker::UiTab.new(
          {id:2, key: tab_key,name:"Popular",url: popular_posts_path,controller:"posts",action:"popular"}
          ))
        @page_links.push(Feedbacker::UiTab.new(
          {id:3, key: tab_key,name:"Active",url: active_posts_path,controller:"posts",action:"active"}
          ))
        @page_links.push(Feedbacker::UiTab.new(
          {id:4, key: tab_key,name:"New post",url: new_post_path,controller:"posts",action:"new"}
          ))
      end
      def load_posts_tabs
        @page_tabs = []

        tab_key = "pageTab"
        @page_tabs.push(Feedbacker::UiTab.new(
          {id: 1, key: tab_key, 
          name: "Feedback", 
          count: nil,
          content: "Test" #nil #render_to_string(partial: "community/votes/main", locals: {object: @preview, user: current_user,upvote_only: true, show_count: true}, layout: false)
          }
          ))
         @page_tabs.push(Feedbacker::UiTab.new(
          {id: 2, key: tab_key, 
          name: "Rate", 
          count: nil,
          content: "Test2" #nil #render_to_string(partial: "community/votes/main", locals: {object: @preview, user: current_user,toggles_only: true, show_count: true}, layout: false)
          }
          ))

        @page_tabs.push(Feedbacker::UiTab.new(
          {id: 3, key: tab_key, 
          name: "Moderate", 
          count: nil,
          content: "Test3" #nil #render_to_string(partial: "community/votes/moderation", locals: {object: @preview, user: current_user, only_if_set: false, vote: nil, labels:Community::Voting::VOTESCOPE_LABELS,wrap_css:"bg-light",row_wrap_css:"mx-2 text-left"}, layout: false)
          }
          ))

      end




    module ClassMethods


    end


  end
end
