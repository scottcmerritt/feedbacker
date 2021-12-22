class CommentsController < ApplicationController
  before_action :authenticate_user!
  

  def create
    commentable = commentable_type.constantize.find(commentable_id)
    @extra_fields = extra_fields
    @comment = Comment.build_from(commentable, current_user.id, body,extra:@extra_fields)

    @form_id = comment_params[:form_id]

    respond_to do |format|
      if @comment.save
        @target = commentable

        @target.announce_comment! sender:current_user if @target.respond_to?(:announce_comment!)

        make_child_comment
        #format.html  { redirect_to(:back, :notice => 'Comment was successfully added.') }
        format.html { redirect_back notice: 'Comment was successfully added.', fallback_location: root_path }
        format.js do
          
          @new_comment = Comment.build_from(commentable, current_user.id, "",extra:@extra_fields)
          @comment_filters = {subject: @comment.subject} unless @comment.subject.blank?
          @comment_values = @comment_filters if @comment_filters
          render "comments/show_added"  #redirect_back notice: 'Comment was successfully added.', fallback_location: root_path }
        end
      else
        format.html  { render :action => "new" }
        format.js  { render :action => "new" }
      end
    end
  end




  private

  def comment_params
    params.require(:comment).permit(:title,:subject,:body, :commentable_id, :commentable_type, :comment_id,:form_id)
  end

  def commentable_type
    comment_params[:commentable_type]
  end

  def commentable_id
    comment_params[:commentable_id]
  end

  def comment_id
    comment_params[:comment_id]
  end

  def extra_fields
    vals = {}
    vals.merge({subject:subject}) unless subject.blank?
  end

  def body
    comment_params[:body]
  end
  def subject
    comment_params[:subject]
  end

  def make_child_comment
    return "" if comment_id.blank?

    @parent_comment = Comment.find comment_id
    @comment.move_to_child_of(@parent_comment)
  end

end