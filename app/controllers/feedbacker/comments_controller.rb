module Feedbacker
class CommentsController < ::ApplicationController
  before_action :authenticate_user!
  before_action :authenticate_admin!, only: :destroy

  def create
    commentable = commentable_type.constantize.find(commentable_id)
    @comment = Comment.build_from(commentable, current_user.id, body)

    respond_to do |format|
      if @comment.save
        make_child_comment
        #format.html  { redirect_to(:back, :notice => 'Comment was successfully added.') }
        format.html { redirect_back notice: 'Comment was successfully added.', fallback_location: root_path }
      else
        format.html  { render :action => "new" }
      end
    end
  end

  # '/engage/comment/:id/:scope'
  # engage_comment_path
  def engage
    @frame = params[:frame]

    scope_keys = {"flag"=>"flagged","like"=>"liked","love"=>"loved"}
    @scope = params[:scope]
    @comment = Comment.find_by(id: params[:id])
    if params[:undo]
      current_user.unfavorite(@comment, scope: scope_keys[@scope].to_sym) if scope_keys[@scope]
    else
      current_user.favorite(@comment, scope: scope_keys[@scope].to_sym) if scope_keys[@scope]
    end
  end

  def destroy
    @comment = Comment.find_by(id:params[:id])
    @removed_id = @comment.id.to_s

    @commentable = @comment.commentable
    @comment.destroy
    

    respond_to do |format|
      format.html do 
        flash[:notice] = "Comment removed"
        redirect_to @commentable rescue redirect_to(main_app.root_path)
      end
      format.js do
        @frame = params[:frame]
      end
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:body, :commentable_id, :commentable_type, :comment_id)
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

  def body
    comment_params[:body]
  end

  def make_child_comment
    return "" if comment_id.blank?

    parent_comment = Comment.find comment_id
    @comment.move_to_child_of(parent_comment)
  end

end
end