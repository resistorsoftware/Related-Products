require 'rubygems'
require 'haml'
require 'sinatra'
require 'json'
require File.dirname(__FILE__) + '/lib/sinatra/shopify'

get '/related' do      
  authorize! 
  @product = ShopifyAPI::Product.find(params[:id])     
  haml :related
end

# hitting this action with tags should assign a metafield known as related_products with all the products that matched the tag(s)
post '/related' do
   authorize!  
   #ShopifyAPI::Metafield.delete(64032)      
   puts "Looking Products with tags #{params[:tags]}\n"     
   @tags = params[:tags].split(',')     
   @product = ShopifyAPI::Product.find(params[:id])
   
   # mf = {
   #   :namespace => 'engravings',
   #   :value => 'sample',
   #   :value_type => 'string'
   # }.merge!(item)
   # product.add_metafield(ShopifyAPI::Metafield.new(mf)
        
   @collection = ShopifyAPI::CustomCollection.find(:first, :params => {:title => @product.handle})
   # for each tag, loop through all the products in the store looking for matchs
   all = ShopifyAPI::Product.find(:all)
   puts "Found there are #{all.length} products in this store to check"
   results = []
   unless @tags.empty?
     all.each do |product|
       unless product.tags.empty? or (product.id == @product.id) 
         # User checks tags, and product has tags so away we go.
         puts "Product tags #{product.tags}\n" 
         source = product.tags.strip().split(',') 
         max_size = @tags.length + source.length                  
         puts "@tag size #{@tags.length}, source size #{source.length}\n"
         test = @tags + source   
         puts "Test array, #{test}, Test size #{test.length}, max_size #{max_size}\n"    
         if test.uniq.size < max_size
           puts "We found a product with tag(s) #{source} matching from #{@tags} so add it to the collection\n" 
           #todo: build a JSON Object for this... 
           results << product
         end
         test.clear
       else 
         puts "Product #{product.title} had no tags!"
       end  
     end
   end
   unless results.empty?                            
     mf = {
       :namespace => 'related_products',
       :value_type => 'string',
       :value => results.to_json,
       :key => 'related_products',
       :description => ""
     }
     @product.add_metafield(ShopifyAPI::Metafield.new(mf))
     puts "Added a new metafield"
   end
   haml :related  
end
   