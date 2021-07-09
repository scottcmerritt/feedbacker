Feedbacker::Engine.routes.draw do
	root controller: :home, action: :index
	resources :comments
	resources :translates
	resources :translate_keys, path: "translations"

	match '/demo(/:filter)' =>"demo#index", :as => :demo, :via=>:get
	match '/admin(/:filter)' =>"admin#index", :as => :admin, :via=>:get
end
