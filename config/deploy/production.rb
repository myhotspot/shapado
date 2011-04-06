domain = "qa.dmteam.ru"
server domain, :web, :app
server domain, :db, :primary => true

set :branch, "master"
set :mysql_adapter, "pg"
set :rails_env, "production"
set :environment, "production"