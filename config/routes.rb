Feedbacker::Engine.routes.draw do
	root controller: :home, action: :index
	resources :comments #, :admin
	resources :translates, :emails, :menus
	resources :translate_keys, path: "translations"
	resources :rooms, :room_messages # :orgs, 


	match '/engage/:otype/:id/:scope' => 'connect#engage', :as => :engage_resource, :via=> [:get,:post], otype: "comment"
	
	match "/add/connection/:otype/:id" => "connect#add", :as => :add_connection, :via=>:get
  	match "/cancel/connection/:otype/:id" => "connect#cancel", :as => :cancel_connection, :via=>:get
  	match "/connections" => "connect#list", :as => :connections, :via=>:get

	match '/ac/search/select/user' => "chat#search_select", :as => :search_select_user, :via=>[:get,:post]
	match '/ac/search/users(/:q)' => "chat#autocomplete_search", :as => :autocomplete_search_users, :via=>[:get,:post]
	#match '/search/rooms(/:q)' =>"rooms#search", :as => :search_rooms, :via=>[:get,:post]

	match '/conversations(/:status)' => 'chat#conversations', :as => :user_conversations, :via => :get
	match '/conversation/:id' => 'rooms#show', :as => :user_conversation, :via => :get
	match '/add/conversation(/:target_id)' => 'chat#conversations_add', :as => :user_conversations_add, :via => :get

	match "/message/remove/:id" => "room_messages#soft_remove", :as=>:room_message_soft_remove, :via=>:post


	match '/tag/search' => 'tags#search', :as => :search_tag, :via=> :post
	match '/tag/add' => 'tags#add', :as => :add_tag, :via=> [:post,:get]
	match '/tag/remove' => 'tags#remove', :as => :remove_tag, :via=> :delete
	match '/tag/update(/:id)' => 'tags#update', :as => :update_tag, :via=> :patch
	match '/tag/delete(/:id)' => 'tags#destroy', :as => :destroy_tag, :via=> :delete
	
	match '/admin/about/translations' =>"translates#about", :as => :translates_about, :via=>[:get,:post]
	match '/admin/search/translations' =>"translate_keys#search", :as => :translates_search, :via=>[:get,:post]

	match '/translated/pages' =>"translate_keys#translated_pages", :as => :translated_pages, :via=>[:get,:post]

	match '/admin/delayed/translates' =>"translate_keys#delayed", :as => :translates_delayed, :via=>[:get,:post]


	match '/admin/cms' =>"translates#cms", :as => :translates_cms, :via=>[:get,:post]
	match '/admin/clear/translate/miss_key' =>"translates#clear_misskey", :as => :translates_clear_misskey, :via=>[:get,:post]
	match '/admin/approve/translate/default' =>"translates#approve_default", :as => :translates_approve_default, :via=>[:get,:post]

	match '/admin/todo/translates' =>"translates#todo", :as => :translates_todo, :via=>[:get,:post]

	
	match '/admin/page/ideas' => 'admin#page_ideas', :as=> :admin_page_ideas, :via=>[:get,:post]
	
	match '/admin/contact_us' => 'admin#contact_us', :as=> :admin_contact_us, :via=>:post
	match '/admin/logins' => 'admin#logins', :as=> :admin_logins, :via=>[:get,:post]
	match '/admin/messages' => 'admin#messages', :as=> :admin_messages, :via=>[:get,:post]
	match '/admin/message/user(/:user_id)' => 'admin#send_user_message', as: :admin_send_user_message, :via=>[:get,:post]

	match '/admin/visitsor/actions' => 'admin#visitor_actions', :as=> :admin_visitor_actions, :via=>[:get,:post]
	match '/admin/visits/referrers' => 'admin#visit_referrers', :as=> :admin_visit_referrers, :via=>:get
	match '/admin/visits/locations' => 'admin#visit_locations', :as=> :admin_visit_locations, :via=>:get
	match '/admin/public/locations' => 'admin#public_locations', :as=> :admin_public_locations, :via=>:get

	match '/admin/visits' => 'admin#visits', :as=> :admin_visits, :via=>:get


	get '/admin/db(/:q)' => 'admin#db', as: :admin_db
  	get '/admin/analytics(/:q)' => 'admin#analytics', as: :admin_analytics
  	get '/admin/cleanup(/:query_id)' => 'admin#cleanup', as: :admin_cleanup
	get '/admin/tags(/:q)' => 'admin#tags', as: :admin_tags
	get '/admin/lists(/:q)' => 'admin#lists', as: :admin_lists
	get '/admin/list(/:ttype)' => 'admin#list', as: :admin_list

	get '/admin/cache(/:q)' => 'admin#cache', as: :admin_cache


	match '/admin/users(/:role)' => 'admin#users', as: :admin_users, :via => :get
	match '/admin/flag/user(/:id)' => 'admin#flag_spammer', :as => :user_flag_spammer, :via=> :post
	match '/admin/roles/change' => 'admin#modify_role', :as => :modify_role, :via => [:get,:post]
	match '/confirm/user/:id' => 'admin#user_confirm', :as => :user_confirm, :via => :post
	
	match '/admin/html/sandbox' => 'admin#html_sandbox', :as=> :admin_html_sandbox, :via=>:get
	match '/admin/html/diff' => 'admin#html_diff', :as=> :admin_html_diff, :via=>:post


	match '/admin(/:q)' => 'admin#index', as: :admin, :via => :get


	match '/demo(/:filter)' =>"demo#index", :as => :demo, :via=>:get
	#match '/admin(/:filter)' =>"admin#index", :as => :admin, :via=>:get


	#match '/profile(/:id)/interests' => 'users#interests', :as => :profile_interests, :via => :get, order: "desc"
  	#match '/profile(/:id)/disinterests' => 'users#interests', :as => :profile_disinterests, :via => :get

end
