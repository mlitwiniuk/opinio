class Opinio::CommentsController < ApplicationController
  include Opinio::Controllers::InternalHelpers
  include Opinio::Controllers::Replies if Opinio.accept_replies

  def index
    @comments = resource.comments.page(params[:page])
  end

  def create
    #@comment = resource.comments.build(params[:comment])
    @comment = resource.comments.build(comment_params)
    @comment.owner = send(Opinio.current_user_method)

    respond_to do |format|
      if @comment.save
        format.js
        format.html do
          set_flash(flash_area, message)
          redirect_to(opinio_after_create_path(resource))
        end
      else
        format.js { render :json => @comment.errors, :status => :unprocessable_entity }
        format.html do
          set_flash(flash_area, message)
          redirect_to(opinio_after_create_path(resource))
        end
      end
    end
  end

  def destroy
    @comment = Opinio.model_name.constantize.find(params[:id])

    if can_destroy_opinio?(@comment)
      @comment.destroy
      set_flash(:notice, t('opinio.messages.comment_destroyed'))
    else
      #flash[:error]  = I18n.translate('opinio.comment.not_permitted', :default => "Not permitted")
      logger.warn "user #{send(Opinio.current_user_method)} tried to remove a comment from another user #{@comment.owner.id}"
      render :text => "unauthorized", :status => 401 and return
    end

    respond_to do |format|
      format.js
      format.html { redirect_to( opinio_after_destroy_path(@comment) ) }
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:body)
  end
  
end
