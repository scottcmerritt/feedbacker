module Feedbacker
  module Generators
    class InitializerGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('templates', __dir__)

      def copy_initializer_file
        copy_file "comments_controller.rb", "app/controllers/#{file_name}.rb"
        copy_file "posts_controller.rb", "app/controllers/posts_controller.rb"

#        copy_file "initializer.rb", "config/initializers/#{file_name}.rb"
      end
    end
=begin
    class InitializerGenerator < Rails::Generators::Base
      def create_initializer_file
        create_file "config/initializers/feedbacker.rb", "# Add Feedbacker initialization content here"
      end
    end
=end
  end
end