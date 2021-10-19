Feedbacker::Engine.routes.draw do
	root controller: :home, action: :index
	resources :comments #, :admin
	resources :translates
	resources :translate_keys, path: "translations"


	match '/admin/about/translations' =>"translates#about", :as => :translates_about, :via=>[:get,:post]
	match '/admin/search/translations' =>"translate_keys#search", :as => :translates_search, :via=>[:get,:post]

	match '/admin/cms' =>"translates#cms", :as => :translates_cms, :via=>[:get,:post]
	match '/admin/todo/translates' =>"translates#todo", :as => :translates_todo, :via=>[:get,:post]

	get '/admin/db(/:q)' => 'admin#db', as: :admin_db
  	get '/admin/analytics(/:q)' => 'admin#analytics', as: :admin_analytics
  	get '/admin/cleanup(/:query_id)' => 'admin#cleanup', as: :admin_cleanup
	get '/admin/tags(/:q)' => 'admin#tags', as: :admin_tags
	match '/admin/users(/:role)(/:q)' => 'admin#users', as: :admin_users, :via => :get
	match '/admin/flag/user(/:id)' => 'admin#flag_spammer', :as => :user_flag_spammer, :via=> :post
	match '/admin/roles/change' => 'admin#modify_role', :as => :modify_role, :via => :post

	match '/demo(/:filter)' =>"demo#index", :as => :demo, :via=>:get
	#match '/admin(/:filter)' =>"admin#index", :as => :admin, :via=>:get


	#match '/profile(/:id)/interests' => 'users#interests', :as => :profile_interests, :via => :get, order: "desc"
  	#match '/profile(/:id)/disinterests' => 'users#interests', :as => :profile_disinterests, :via => :get

end
