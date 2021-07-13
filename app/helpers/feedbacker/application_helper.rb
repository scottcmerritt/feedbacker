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
      current_user.nil? ? "No user found" : "Current user is #{current_user.id}"
    end

     def feedbacker_comments target:, new_comment: nil
      render partial: "comments/template", locals: {commentable: target, new_comment: new_comment} 
    end

    


  end
end
