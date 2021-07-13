module Feedbacker
  module Configure

    # built from: https://github.com/RolifyCommunity/rolify/blob/master/lib/rolify/configure.rb

    @@dynamic_shortcuts = false
    @@orm = "active_record"

    @@default_list_ui = "list" # or table
    @@theme = 0
    

    def configure(*settings)
      return if !sanity_check(settings)
      yield self if block_given?
    end

    def dynamic_shortcuts
      @@dynamic_shortcuts
    end

    def dynamic_shortcuts=(is_dynamic)
      @@dynamic_shortcuts = is_dynamic
    end

    def orm
      @@orm
    end

    def orm=(orm)
      @@orm = orm
    end

    # not implemented
    def use_mongoid
      self.orm = "mongoid"
    end

    def use_dynamic_shortcuts
      return if !sanity_check([])
      self.dynamic_shortcuts = true
    end

    def use_defaults
      configure do |config|
        config.dynamic_shortcuts = false
        config.orm = "active_record"
        config.default_list_ui = "list"
        config.theme = 0
      end
    end

    def default_list_ui=(list_ui)
      @@default_list_ui = list_ui
    end

    def default_list_ui
      @@default_list_ui
    end

    def theme=(theme_id)
      @@theme = theme_id
    end

    def theme
      @@theme
    end

    private

    def sanity_check settings
      true
    end

   

  end
end