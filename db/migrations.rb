##  These migrations can be executed from the project's root directory like so:
##
##    $ rm db/partifi.db; ruby db/migrations.rb
##

ENV["DATABASE_URL"] ||= "sqlite://db/partifi.db" # FIXME: not DRY

require File.expand_path("../partifi", File.basename(__FILE__))

Partifi::DB.create_table :events do
  primary_key :id
  Time :starts_at
  Time :ends_at
end

Partifi::DB.create_table :songs do
  primary_key :id
  String :name
  String :artist
  String :href
  String :img
  Interger :event_id
  Time :created_at
  Time :updated_at
  Time :started_at
  Time :deleted_at
  add_index [:event_id, :href]
end

Partifi::DB.create_table :votes do
  primary_key :id
  Integer :song_id
  Integer :user_id
  String :status
  unique [:song_id, :user_id]
end
