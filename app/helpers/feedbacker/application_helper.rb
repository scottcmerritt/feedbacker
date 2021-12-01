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
  
    def tag_with_remove tag_lbl:nil, lbl:, remove_keys:nil, wrap_css: "d-flex align-items-center border p-1 me-1",link_css: "text-danger mx-1"
      
      tag_full_label = tag.div safe_join([tag.span(tag_lbl,class:"text-muted"),tag.span(lbl,class:"fw-bold")])

      tag.div safe_join([tag_full_label, link_to("X",feedbacker.url_for(request.parameters.except(remove_keys)), class: link_css)]), class: wrap_css
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

  def feedbacker_paginate data, page: 1, wrap_css: nil
    page = [1,"1",nil].include?(page) ? 1 : page.to_i
    prev_page = current_path(page:page-1) 
    next_page = current_path(page:page+1)

    begin
      render(partial:"util/my_paginate", locals: {data: data, page:page,paths: {prev:prev_page,next:next_page}, wrap_css:wrap_css})
    rescue
#     render(partial:"feedbacker/util/my_paginate", locals: {data: data, paths: {prev:prev_page,next:next_page}})      
     render(partial:"util/my_paginate", locals: {data: data, paths: {prev:prev_page,next:next_page}, wrap_css:wrap_css})      
    end

  end

  def isolate_param url, param: "q="
    #url="www.testurl.com?q=test+query+here&extra_stuff&"
    search_part = url.split(param)[1] rescue nil
    search_part = search_part.split("&")[0] unless search_part.nil?
    search_part = search_part.gsub("+"," ") unless search_part.nil?
    search_part = search_part.gsub("%20"," ") unless search_part.nil?
    search_part.nil? ? "" : "<div class='mx-1'><span class='text-muted'>Searched for:</span> <span class='fw-bold text-dark'>#{search_part}</span></div>"
  end
    


  end
end
