Feedbacker::Engine.routes.draw do
	root controller: :home, action: :index
	resources :comments #, :admin
	resources :translates, :emails
	resources :translate_keys, path: "translations"



	#match '/tag/search' => 'tags#search', :as => :search_tag, :via=> :post
	#match '/tag/add' => 'tags#add', :as => :add_tag, :via=> [:post,:get]
	#match '/tag/remove' => 'tags#remove', :as => :remove_tag, :via=> :delete
	match '/tag/update(/:id)' => 'tags#update', :as => :update_tag, :via=> :patch
	match '/tag/delete(/:id)' => 'tags#destroy', :as => :destroy_tag, :via=> :delete
	
	match '/admin/about/translations' =>"translates#about", :as => :translates_about, :via=>[:get,:post]
	match '/admin/search/translations' =>"translate_keys#search", :as => :translates_search, :via=>[:get,:post]

	match '/admin/delayed/translates' =>"translate_keys#delayed", :as => :translates_delayed, :via=>[:get,:post]


	match '/admin/cms' =>"translates#cms", :as => :translates_cms, :via=>[:get,:post]
	match '/admin/todo/translates' =>"translates#todo", :as => :translates_todo, :via=>[:get,:post]

	

	get '/admin/db(/:q)' => 'admin#db', as: :admin_db
  	get '/admin/analytics(/:q)' => 'admin#analytics', as: :admin_analytics
  	get '/admin/cleanup(/:query_id)' => 'admin#cleanup', as: :admin_cleanup
	get '/admin/tags(/:q)' => 'admin#tags', as: :admin_tags
	get '/admin/cache(/:q)' => 'admin#cache', as: :admin_cache


	match '/admin/users(/:role)(/:q)' => 'admin#users', as: :admin_users, :via => :get
	match '/admin/flag/user(/:id)' => 'admin#flag_spammer', :as => :user_flag_spammer, :via=> :post
	match '/admin/roles/change' => 'admin#modify_role', :as => :modify_role, :via => :post
	match '/confirm/user/:id' => 'admin#user_confirm', :as => :user_confirm, :via => :post
	
	match '/admin/html/sandbox' => 'admin#html_sandbox', :as=> :admin_html_sandbox, :via=>:get
	match '/admin/html/diff' => 'admin#html_diff', :as=> :admin_html_diff, :via=>:post


	match '/admin(/:q)' => 'admin#index', as: :admin, :via => :get


	match '/demo(/:filter)' =>"demo#index", :as => :demo, :via=>:get
	#match '/admin(/:filter)' =>"admin#index", :as => :admin, :via=>:get


	#match '/profile(/:id)/interests' => 'users#interests', :as => :profile_interests, :via => :get, order: "desc"
  	#match '/profile(/:id)/disinterests' => 'users#interests', :as => :profile_disinterests, :via => :get

end
