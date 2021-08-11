Feedbacker::Engine.routes.draw do
	root controller: :home, action: :index
	resources :comments
	resources :translates
	resources :translate_keys, path: "translations"

	match '/demo(/:filter)' =>"demo#index", :as => :demo, :via=>:get
	match '/admin(/:filter)' =>"admin#index", :as => :admin, :via=>:get

	#match '/profile(/:id)/interests' => 'users#interests', :as => :profile_interests, :via => :get, order: "desc"
  	#match '/profile(/:id)/disinterests' => 'users#interests', :as => :profile_disinterests, :via => :get

end
