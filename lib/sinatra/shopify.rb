require 'sinatra/base'
require 'active_support'
require 'active_resource'

#gem 'shopify_api'
require 'shopify_api'

module Sinatra
  module Shopify

    module Helpers
      def current_shop
        session[:shopify]
      end

      def authorize!
        redirect '/login' unless current_shop

        ActiveResource::Base.site = session[:shopify].site
      end

      def logout!
        session[:shopify] = nil
      end
    end

    def self.registered(app)     
      puts "Registering the Application\nLooking for credentials in #{File.dirname(__FILE__)}\n"
      app.helpers Shopify::Helpers
      app.enable :sessions

      # load config file credentials
      if File.exist?(File.dirname(__FILE__) + "/shopify.yml")
        config = File.dirname(__FILE__) + "/shopify.yml"
        credentials = YAML.load(File.read(config))    
        puts "Credentials are #{credentials}\n"
        ShopifyAPI::Session.setup(credentials)
      else
        ShopifyAPI::Session.setup(
          :api_key => ENV['SHOPIFY_API_KEY'],
          :secret => ENV['SHOPIFY_API_SECRET']
        )
      end
      
      app.get '/login' do
        haml :login
      end
      
      app.get '/logout' do
        logout!
        redirect '/'
      end

      app.post '/login/authenticate' do      
        puts "The shop is #{params[:shop]}\nredirecting to #{ShopifyAPI::Session.new(params[:shop]).create_permission_url}\n\n" 
        redirect ShopifyAPI::Session.new(params[:shop]).create_permission_url
      end
      
      app.get '/login/finalize' do
        shopify_session = ShopifyAPI::Session.new(params[:shop], params[:t])
        if shopify_session.valid?
          session[:shopify] = shopify_session

          return_address = session[:return_to] || '/'
          session[:return_to] = nil
          redirect return_address
        else
          redirect '/login'
        end
      end
    end
  end

  register Shopify
end
