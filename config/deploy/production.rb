domain = "qa.dmteam.ru"
server domain, :web, :app
server domain, :db, :primary => true

set :branch, "next"
set :mysql_adapter, "pg"
set :rails_env, "production"
set :environment, "production"