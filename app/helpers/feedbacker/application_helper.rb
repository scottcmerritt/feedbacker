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
  
    def tag_with_remove tag_lbl:nil, lbl:, remove_keys:nil, wrap_css: "d-flex align-items-center bg-plain border p-1 me-1",link_css: "text-danger mx-1"
      
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

    # TODO: implement search filters, or tag filters??
    # TODO: maybe add tag params: for adding page::10 and filtering by page=10
    # fields: [which fields to permit, default just :body]
    # values: what values to set in new fields
    # hidden: which fields to visually hide? (despite being in page/form)
    def feedbacker_comments target:, new_comment: nil, filters: nil, fields: [:body], values: nil, hidden: nil, with_wrap: true
      locals = {commentable: target, new_comment: new_comment,with_wrap:with_wrap}
      locals = locals.merge({comments: filter_comments(target.root_comments,filters:filters)}) unless filters.nil?
      locals = locals.merge({fields:fields,values:values})
      render partial: "comments/template", locals: locals
    end

    def filter_comments filtered_comments,filters:nil
      filtered_comments = filtered_comments.where("subject = ?",filters[:subject]) unless filters.nil?
      filtered_comments.sort_by{|row| row.created_at}.reverse
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

  
  def default_tag_css font_size: "fs-7", is_mobile: (respond_to?(:browser) ? browser.mobile? : true), extra_css: ""
    # "mt-0 m-1 p-1 fs-8 #{browser.mobile? ? "rounded p-1 py-tiny" : "rounded-pill px-2 mb-1" } bg-light border text-decoration-none" if local_assigns[:tag_css].nil?
    #{}"badge m-0 me-1 p-1 #{is_mobile ? "rounded py-tiny" : "rounded-pill px-2 mb-1" } border text-decoration-none bg-primary #{font_size} #{extra_css}" 
    "badge m-0 me-1 px-1 #{is_mobile ? "rounded py-tiny" : "rounded py-tiny mb-0" } border text-decoration-none bg-primary #{font_size} #{extra_css}" 
  end

  def default_tab_frame_css
    "d-flex align-items-center my-1 border-bottom border-2 border-dark"
  end
  def default_tab_css_off margin: "me-1"
    "bg-plain text-secondary btn btn-sm border rounded-0 rounded-top #{margin}"
  end
  def default_tab_css_on margin: "me-1"
    "bg-dark text-light btn btn-sm rounded-0 rounded-top #{margin}"
  end


  def default_h_css padding: "p-1 px-2", margin: "",font:""
    "d-flex align-items-center bg-dark text-light #{padding} #{margin} #{font}"
  end

  def default_toggle_icons color: "dark", margin: "me-2", font: "fs-5"
    shared_css = "#{font} text-#{color} #{margin}"
    raw "<i class='fa fa-chevron-down #{shared_css} text-collapsed'></i><i class='fa fa-chevron-up #{shared_css} text-expanded'></i>"
  end

  # the idea is to pass the partial to this to reduce several lines of code in an .erb file
  # it doesn't seem to be working well
  def debug_render 
    begin
      yield
    rescue Exception=>ex
      ex
    end
  end
    


  end
end
