module Feedbacker
  module ApplicationHelper
    include Rails.application.routes.url_helpers

    def feedbacker? feature:nil
      if feature.nil?
        return true
      else
        return true if feature == "translate"
      end
    end

    def feedbacker_marketing_link
      tag.div "Automatically created by Feedbacker", class: "p-2 fs-7 text-center"
    end

    def feedbacker_draw target:nil, data: nil 
      "Hello world new version"

      path_prepped = (target.class.name.downcase+"_path").to_sym

      render(partial:"shared/hello", locals: {target: target, path_to_resource:path_prepped, data:data}) # + render(partial:"shared/hello2")
    end


    def feedbacker_profile
      current_user.nil? ? tag.span("Guest") : icon(icon:"user",lbl:"User #{current_user.id}",with_span:true,icon_css:"fs-5") #, [main_app,current_user])
    end

     def feedbacker_comments target:, new_comment: nil
      render partial: "comments/template", locals: {commentable: target, new_comment: new_comment} 
    end


  def current_path(params={})
    feedbacker.url_for(request.params.merge(params))
  end

  def feedbacker_paginate data, page: 1
    page = [1,"1",nil].include?(page) ? 1 : page.to_i
    prev_page = current_path(page:page-1) 
    next_page = current_path(page:page+1)

    begin
      render(partial:"util/my_paginate", locals: {data: data, page:page,paths: {prev:prev_page,next:next_page}})
    rescue
#     render(partial:"feedbacker/util/my_paginate", locals: {data: data, paths: {prev:prev_page,next:next_page}})      
     render(partial:"util/my_paginate", locals: {data: data, paths: {prev:prev_page,next:next_page}})      
    end

  end

    


  end
end
