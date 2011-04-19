set :deploy_to, "/var/rails/staging/ffapi"
set :rails_env, "staging"
set :environment, "staging"
set :rails_env, "staging"

domain = "api.freefrog.ru"
server domain, :web, :app
server domain, :db, :primary => true

set :branch, 'master'
set :mysql_adapter, "mysql"


#after "deploy:restart", "delayed_job:restart"
