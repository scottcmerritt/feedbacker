class TagsController < ApplicationController
	before_action :authenticate_user! #, except: [:updates]
	before_action :set_taggable

	before_action :authenticate_admin!, only: [:update,:destroy]

	def update
		@tag = ActsAsTaggableOn::Tag.find_by(id:params[:id])
		@name = params[:tag][:name]


		unless @name.nil?
			@tag.name = @name
			if @tag.save
				flash[:notice] = "Tag updated"
			else
				flash[:notice] = "Errors updating the tag: #{@tag.errors.full_messages[0]}"
			end
		end

#		@tag.update(name:@name) unless @name.nil?
		
		redirect_to controller: "admin", action: "tags", id: @tag.id #, notice: @tag.errors #{}"Tag updated"
#		render json: @name
	end

	# destroy_tag_path
	def destroy
		@tag = ActsAsTaggableOn::Tag.find_by(id:params[:id])
		cnt = @tag.taggings_count unless @tag.nil?
		@tag.destroy unless @tag.nil?
		flash[:notice] = "Tag removed, and removed from #{cnt} object"
		redirect_to controller: "admin", action: "tags"
	end

	def search
		@q = params[:q]
		otype = params[:otype] #'Book'
		oid = params[:oid]

=begin
		if otype == 'Book'
			@target = Book.find_by(id:oid)
		elsif otype == 'Tag'
			@target = Tag.find_by(id:oid)
		end
=end
		locals = {:js=>false,:tags=>@target.search_tags(@q),target:@target}
     	html = render_to_string(:partial=>"shared/tags/results",:locals=>locals,:layout=>false)

		render json: {html: html} #{}"<div>#{@q}</div>"}
	end

	def add
		authorize! :update, @target # raises exception
		if is_taggable?
			@target.tag_list.add(params[:tag])
			@target.save
			go_to_target
		end
	end


	# remoes a tag FROM target (i.e. from a book)
	def remove
		#if can?(:update, project)
		authorize! :update, @target # raises exception
		if is_taggable?
			@target.tag_list.remove(params[:tag])
			@target.save

			go_to_target
		end
	end

	private

	

	def is_taggable?
		#params[:book_id] || params[:project_id] || params[:post_id]
		Tag.tag_class_names.include? @target.class.name
	end

	def go_to_target
		if @target.class.name == "Tag"
			redirect_to controller: "admin", action: "tags", id: @target.id
		else
			redirect_to @target
		end
	end
	def set_taggable
		@target = get_target
	end
	def get_target
		if Tag.tag_class_names.include? params[:otype]
			params[:otype].constantize.find_by(id:params[:oid])
		end
=begin
		if params[:otype] && params[:otype].downcase == 'tag'
			Tag.find_by(id:params[:oid])
		else
			if params[:book_id]
				Book.find_by(id:params[:book_id])
			elsif params[:project_id] 
				Project.find_by(id:params[:project_id])
			elsif params[:post_id]
				Post.find_by(id:params[:post_id])
			end
		end
=end		
	end
end