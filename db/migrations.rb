require "partifi"

Partifi::DB.create_table :events do
  primary_key :id
  String :facebook_id
  Time :starts_at
  Time :ends_at
end
