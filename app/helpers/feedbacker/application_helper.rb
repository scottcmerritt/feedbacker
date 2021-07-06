module Feedbacker
  module ApplicationHelper
    include Rails.application.routes.url_helpers

    def feedbacker_draw target:nil, data: nil 
      "Hello world new version"


      my_path = (target.class.name.downcase+"s_path").to_sym

      render(partial:"shared/hello", locals: {target: target,path_to_resource:my_path, data:data}) # + render(partial:"shared/hello2")
    end


  end
end
