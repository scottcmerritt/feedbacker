module Feedbacker
  module Configure

    # built from: https://github.com/RolifyCommunity/rolify/blob/master/lib/rolify/configure.rb

    @@dynamic_shortcuts = false
    @@orm = "active_record"

    @@default_list_ui = "list" # or table
    @@theme = 0
    
    @@languages = ["en","es"]
    @@default_language = "en"

    @@default_engage_keys = {"flag"=>"flagged","like"=>"liked","love"=>"loved","agree"=>"agreed"}
    @@default_engage_icons = {"flag"=>{:icon=>"exclamation-triangle",:css=>"text-warning"},"like"=>{:icon=>"thumbs-up",:css=>"text-success"},"love"=>{:icon=>"heart",:css=>"text-danger"},"agree"=>{:icon=>"handshake",:css=>"text-primary"}}

    @@engage_keys = @@default_engage_keys
    @@engage_icons = @@default_engage_icons

    @@service_upgrades = []

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
        config.languages = ["en","es"]
        config.default_language = "en"

        config.engage_keys = @@default_engage_keys
        config.engage_icons = @@default_engage_icons

        # info for updating the provided service (i.e. # of db rows etc...)
        # an array of hash service tiers, example_tier = {name:"Tier 1",rows:100000,price:"$1 billion/month",info:"Some db rows and great customer service"}
        config.service_upgrades = [] 
      end
    end

    def engage_keys=(keys)
      @@engage_keys = keys
    end

    def engage_keys
      @@engage_keys
    end

    def engage_icons=(icons)
      @@engage_icons = icons
    end
    
    def engage_icons
      @@engage_icons
    end

    def service_upgrades=(upgrades)
      @@service_upgrades = upgrades
    end
    def service_upgrades
      @@service_upgrades
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

    def languages
      @@languages
    end
    def default_language
      @@default_language
    end
    
    def languages=(lang_arr)
      @@languages = lang_arr
    end
    def default_language=(lang)
      @@default_language = lang
    end

    private



    def sanity_check settings
      true
    end

  end
end