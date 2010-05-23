require 'rubygems'
require 'haml'
require 'sinatra'
require 'json'
require File.dirname(__FILE__) + '/lib/sinatra/shopify'

get '/' do
  authorize!
  haml :index
end

get '/login' do 
  haml :login
end

get '/logout' do
  logout!
  redirect '/'
end

post '/login/authenticate' do      
  redirect ShopifyAPI::Session.new(params[:shop]).create_permission_url
end

get '/login/finalize' do
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

get '/related' do      
  authorize! 
  @product = ShopifyAPI::Product.find(params[:id]) 
  @results = []
  # if this Product already has metafields, let's check for the related products key
  unless @product.metafields.empty?
    @product.metafields.each do |mf|
      if mf.key = 'related_products'
        JSON.parse(mf.value).each do |product|
          @results << product['title']
        end
      end
    end
  end
  haml :related
end

# hitting this action with tags should assign a metafield known as related_products with all the products that matched the tag(s)
post '/related' do
   authorize!  
   @tags = params[:tags].split(',')     
   @product = ShopifyAPI::Product.find(params[:id])
   @collection = ShopifyAPI::CustomCollection.find(:first, :params => {:title => @product.handle})
   # for each tag, loop through all the products in the store looking for ones that match
   all = ShopifyAPI::Product.find(:all)
   @results = [] # pass this on to the view
   data = [] # data for the metafield
   unless @tags.empty?
     all.each do |product|
       unless product.tags.empty? or (product.id == @product.id) 
         source = product.tags.gsub(/\s/,'').split(',') # remove the nasty Shopify induced extra space
         max_size = @tags.length + source.length                  
         test = @tags + source   
         if test.uniq.length < max_size
           data << product
           @results << product.title
         end
       end
     end
   end
   unless data.empty?                            
     mf = {
       :namespace => 'related_products',
       :value_type => 'string',
       :value => data.to_json,
       :key => 'related_products',
       :description => "Related Products for #{@product.title}"
     }
     @product.add_metafield(ShopifyAPI::Metafield.new(mf))
   end
   haml :related  
end

delete '/destroy' do
  authorize! 
  @product = ShopifyAPI::Product.find(params[:id])
  unless @product.metafields.empty?
    @product.metafields.each do |mf|
      if mf.key = 'related_products'
        ShopifyAPI::Metafield.delete(mf.id)   
      end
    end
  end
  @results = []
  haml :related
end   