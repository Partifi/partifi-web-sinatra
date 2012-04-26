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

  class Songs
    def self.add(data = {}, user_id = nil)
      song_id = self.table.insert(data)
      Votes.create_or_update(:song_id => song_id, :user_id => user_id, :status => 'love') if user_id
      true
    end

    def self.exists?(id)
      !!self.find(id)
    end

    def self.find(id)
      self.table.filter(:event_id => id, :deleted_at => nil)
    end

    def self.remove_from_event(params = {})
      self.table.filter(:event_id => params[:event_id], :href => params[:song], :deleted_at => nil).update(:deleted_at => Time.now)
    end

    def self.table
      DB[:songs]
    end
  end

  class Votes

    def self.create_or_update(params = {})
      existing_vote = self.table.where({:user_id => params[:user_id], :song_id => params[:song_id]}).first

      if existing_vote
        self.table.filter(:id => existing_vote[:id]).update(:status => params[:status])
      else
        self.table.insert(params)
      end
    end

    def self.order_songs_by_votes(songs)
      ids = songs.map {|s| s[:id]}
      songs_and_rank = []
      songs.each {|s| songs_and_rank[s[:id]] = [s, 0, [], []]} # maps to [song, rank, love, hate]
      self.table.filter(:song_id => ids).all.each do |vote|
        ranking = songs_and_rank[vote[:song_id]]
        if vote[:status] == 'love' then
          ranking[1] += 1
          ranking[2] << vote[:user_id] # love
        else
          ranking[1] -= 1
          ranking[3] << vote[:user_id] # hate
        end
      end
      songs_and_rank.compact!
      songs_and_rank.sort! {|a,b| b[1] <=> a[1]}
      songs_and_rank.map {|song, _, lovers, haters|
         song.to_hash.merge(:lovers => lovers, :haters => haters) }
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
      }, params[:user_id]).inspect
    end

    get "/playlist/:id" do
      content_type :json

      songs = Songs.find(params[:id]).all
      result = Votes.order_songs_by_votes(songs).map(&:to_hash)

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

    # TODO: make more restful with delete action
    post "/playlist/:event_id/:song_href" do
      Songs.remove_from_event(:song => params[:song_href], :event_id => params[:event_id])
      200
    end

  end

end