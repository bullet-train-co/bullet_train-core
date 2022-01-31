Rails.application.routes.draw do
  namespace :account do
    shallow do
      namespace :cloudinary do
        resources :upload_signatures
      end
    end
  end
end
