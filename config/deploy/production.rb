domain = "qa.dmteam.ru"
server domain, :web, :app
server domain, :db, :primary => true

set :mysql_adapter, "pg"
set :port, 2122
set :rails_env, "production"
set :environment, "production"