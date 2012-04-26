require "bundler/setup"

require 'compass' #must be loaded before sinatra
require "sinatra/base"
require "sequel"
require "json"
require "open-uri"
require "hallon"

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

  class Songs
    def self.add(data)
      self.table.insert(data)
      true
    end

	def self.image_add(href, img)
		self.table.filter(:href => href).update(:img => img);
	end

    def self.exists?(id)
      !!self.find(id)
    end

    def self.find(id)
      self.table.filter(:event_id => id)
    end

    def self.table
      DB[:songs]
    end
  end

  class Votes

    def self.create_or_update(params)
      existing_vote = self.table.where({:user_id => params[:user_id], :song_id => params[:song_id]}).first

      if existing_vote
        self.table.filter(:id => existing_vote[:id]).update(:status => params[:status])
      else
        self.table.insert(params)
      end
    end

    def self.table
      DB[:votes]
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
      Event.add_id(params[:event_id]).inspect
    end

    post "/playlist/:event_id" do  
	    Songs.add({
	      "name" => params[:name],
	      "artist" => params[:artist],
	      "href" => params[:uri],
	      "event_id" => params[:event_id]
	    }).inspect
    end
	
	post "/update/:uri" do
		Songs.image_add(params[:uri], params[:img]).inspect
	end
	
    get "/playlist/:id" do
      content_type :json

      # TODO: order by love/hate status
      result = Songs.find(params[:id]).naked.left_join(:votes, :song_id => :id).all

      playlist = { "Playlist" => []}

      if result
        playlist = { "Playlist" => result }
      end

      playlist.to_json
   end

    get "/search/:query" do
      content_type :json
      open("http://ws.spotify.com/search/1/track.json?q=" + URI.encode(params[:query])).read
    end
		
    post "/vote/:id" do
      Votes.create_or_update(:song_id => params[:id], :status => params[:status], :user_id => params[:user_id])

      200
    end

  end

end