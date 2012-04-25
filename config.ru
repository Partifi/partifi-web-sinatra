ENV["DATABASE_URL"] ||= "sqlite://db/participants.db"
require "./partifi"

run Partifi::App
