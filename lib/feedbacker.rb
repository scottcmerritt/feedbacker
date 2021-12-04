require "feedbacker/version"
require "feedbacker/engine"

require 'kaminari'

require 'feedbacker/configure'

module Feedbacker
  # Your code goes here...
  #require "app/models/feedbacker/concerns"
  extend Configure

  def feedbacker(options = {})
    #include Role
    #extend Dynamic if Rolify.dynamic_shortcuts


  end


  # NOT sure if this WORKS
  #class Feedbacker < Rails::Engine
    #isolate_namespace Myengine # remove this line to merge routes
   # ...
  #end

end

require "feedbacker/concerns/feedbacker_util"
require "feedbacker/concerns/feedbacker_comment_util"
require "feedbacker/concerns/feedbacker_main_controller"
require "feedbacker/concerns/feedbacker_users_controller"
require "feedbacker/concerns/feedbacker_posts_controller"
require "feedbacker/concerns/feedbacker_admin_controller"

require "feedbacker/concerns/user_info"

require 'diffy'