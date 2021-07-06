module Feedbacker
  module ApplicationHelper
    include Rails.application.routes.url_helpers

    def feedbacker_draw target:nil, data: nil 
      "Hello world new version"

      path_prepped = (target.class.name.downcase+"s_path").to_sym

      render(partial:"shared/hello", locals: {target: target, path_to_resource:path_prepped, data:data}) # + render(partial:"shared/hello2")
    end


  end
end
