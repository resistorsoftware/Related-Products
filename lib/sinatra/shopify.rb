require 'sinatra/base'
require 'active_support'
require 'active_resource'
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
      app.helpers Shopify::Helpers
      app.enable :sessions

      # load config file credentials
      if File.exist?(File.dirname(__FILE__) + "/shopify.yml")
        config = File.dirname(__FILE__) + "/shopify.yml"
        credentials = YAML.load(File.read(config))    
        ShopifyAPI::Session.setup(credentials)
      else                           
        ShopifyAPI::Session.setup(
          :api_key => ENV['SHOPIFY_API_KEY'],
          :secret => ENV['SHOPIFY_API_SECRET']
        )
      end
      
  end

  register Shopify
end
