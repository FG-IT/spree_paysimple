Spree::Core::Engine.add_routes do
  # Add your extension routes here
  get '/paysimple/auth', :to => "paysimple#auth", :as => :auth_paysimple
end
