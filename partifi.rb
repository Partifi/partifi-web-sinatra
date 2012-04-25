require "bundler/setup"

require 'compass' #must be loaded before sinatra
require "sinatra/base"
require "sequel"
require "json"


module Partifi
  DB = Sequel.connect(ENV["DATABASE_URL"])

  class Events
    def self.table
      DB[:events]
    end
  end

  class App < Sinatra::Base
    set :static, true
    set :sass_mtime, File.mtime(File.join(root, "views/sass"))

    configure do
      Compass.configuration do |config|
        config.project_path = File.dirname(__FILE__)
        config.sass_dir = "views"
        config.images_dir = "public/images"
        config.http_path = "/"
        config.http_images_path = "/images"
        config.http_stylesheets_path = "/stylesheets"
        config.preferred_syntax = :scss
        config.output_style = :compressed unless environment == :development
        config.sass_options = { :cache => false }
      end
    end

    if production?
      before { expires 43200, :public }
    end

    get "/" do
      erb :index
    end

    get "/stylesheets/screen.css" do
      content_type 'text/css', :charset => 'utf-8'
      last_modified(self.class.sass_mtime)
      scss(:"sass/screen", Compass.sass_engine_options)
    end

    get "/playlist/:event_id" do
      # return playlist for event
      content_type :json
      
            
      {
	"Playlist" => [
		{
			"uri" => "spotify:track:7bzinfns7drLnzylnK6L9S",
			"love" => [1281485772, 1281485772, 1281485772],
			"hate" => [1281485772, 1281485772]
		},
		{
			"uri" => "spotify:track:0d2O5TNHO2T5XR95TVmgfp",
			"love" => [1281485772, 1281485772, 1281485772],
			"hate" => [1281485772, 1281485772]
		}
	]
}.to_json

    end
  end

end
