module Feedbacker
  class Engine < ::Rails::Engine
    isolate_namespace Feedbacker

#    config.autoload_paths += Dir[Rails.root.join('app', 'models', 'feedbacker','ui', '{*/}')]
  end
end
