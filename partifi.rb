require "bundler/setup"

require 'compass' #must be loaded before sinatra
require "sinatra/base"
require "sequel"
require "json"
require "open-uri"


module Partifi
  DB = Sequel.connect(ENV["DATABASE_URL"])

  class Event
    def self.add_id(id)
      return false if self.exists?(id)

      self.table.insert(:id => id)
      true
    end

    def self.exists?(id)
      !!self.find(id)
    end

    def self.find(id)
      self.table.first(:id => id)
    end

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

    # curl http://localhost:9292/playlist -d facebook_id=2312
    post "/playlist" do
      Event.add_id(params[:facebook_id]).inspect
    end

    get "/playlist/:id" do
      Event.find(params[:id]).inspect
      # return playlist for event
      content_type :json

      {
        "Playlist" => [
          {
            "id" => 1,
            "uri" => "spotify:track:7bzinfns7drLnzylnK6L9S",
            "love" => [1281485772, 1281485772, 1281485772],
            "hate" => [1281485772, 1281485772]
          },
          {
            "id" => 2,
            "uri" => "spotify:track:0d2O5TNHO2T5XR95TVmgfp",
            "love" => [1281485772, 1281485772, 1281485772],
            "hate" => [1281485772, 1281485772]
          }
        ]
      }.to_json
    end

    get "/search/:query" do
      content_type :json
      open("http://ws.spotify.com/search/1/track.json?q=" + URI.encode(params[:query])).read
    end
  end

end
