ENV["DATABASE_URL"] ||= "sqlite://db/partifi.db"
require "./partifi"

run Partifi::App
