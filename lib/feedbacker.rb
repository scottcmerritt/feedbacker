require "feedbacker/version"
require "feedbacker/engine"

require 'kaminari'

module Feedbacker
  # Your code goes here...
  #require "app/models/feedbacker/concerns"

  # NOT sure if this WORKS
  #class Feedbacker < Rails::Engine
    #isolate_namespace Myengine # remove this line to merge routes
   # ...
  #end

end

require "feedbacker/concerns/feedbacker_util"
require "feedbacker/concerns/feedbacker_main_controller"
require "feedbacker/concerns/feedbacker_users_controller"
require "feedbacker/concerns/feedbacker_posts_controller"
require "feedbacker/concerns/feedbacker_admin_controller"