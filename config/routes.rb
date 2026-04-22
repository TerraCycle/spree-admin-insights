Spree::Core::Engine.routes.draw do
  scope '(:locale)', locale: /#{Spree.available_locales.join('|')}/, defaults: { locale: nil } do
    namespace :admin do
      get 'insights/download', to: 'insights#download'
      resources :insights
    end
  end
end
