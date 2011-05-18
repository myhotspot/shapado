require 'bundler/capistrano'

set :stages, %w(zhkh mchs)
set :default_stage, "zhkh"


set :application, "shapado"
set :repository,  "git@github.com:reflow/shapado.git"
set :deploy_to, "/var/rails/shapado"
set :deploy_via, :remote_cache
set :branch, 'site'
set :scm, :git
set :scm_verbose, true
set :use_sudo, false
set :delayed_job_params, "-n 20"
set :db_name_prefix, application.downcase.gsub(/[^a-z]/, '-')

# require multistage. must be here!
require 'capistrano/ext/multistage'

default_run_options[:pty] = true
ssh_options[:forward_agent] = true
ssh_options[:paranoid] = false
ssh_options[:user] = "deploy"


namespace :deploy do
  task :restart, :roles => :app do
    run "touch #{latest_release}/tmp/restart.txt"
  end

  desc "Make symlinks"
  task :symlink_configs do
    run "ln -nfs #{shared_path}/config/mongoid.yml #{release_path}/config/mongoid.yml"
    run "ln -nfs #{shared_path}/config/openfire.yml #{release_path}/config/openfire.yml"
    run "ln -nfs #{shared_path}/config/shapado.yml #{release_path}/config/shapado.yml"
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/config/auth_providers.yml #{release_path}/config/auth_providers.yml"
  end

  namespace :gems do
    desc "Install required gems"
    task :install do
      run <<-CMD
        cd #{latest_release};
        #{sudo} rake gems:install;
      CMD
    end
  end

  task :create_shared_dirs do
    run <<-CMD
      mkdir #{shared_path}/config;
      mkdir #{shared_path}/db;
    CMD
    #mkdir #{shared_path}/.bundle;
  end

  task :create_log_files do
    run "touch #{shared_path}/log/development.log #{shared_path}/log/production.log #{shared_path}/log/test.log"
  end
  
  desc "Create asset packages for production" 
  task :smart_asset do
    run <<-EOF
      cd #{current_path} && RAILS_ENV=#{rails_env} smart_asset
    EOF
  end
end

namespace :db do
  task :seed do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} rake db:seed"
  end
  
  task  :create do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} rake db:create"
  end
  
  task :create_admin_user do
    run <<-EOS
      cd #{current_path};
      echo "User.create! :email => 'admin@dmteam.ru', :password => 'administrator'; User.last.confirm! rescue nil" | rails console #{rails_env};
    EOS
  end
  
  desc "Create database yaml in shared path"
  task :default do
    db_config = ERB.new <<-EOF
    base: &base
      adapter: #{mysql_adapter}
      socket: /var/run/mysqld/mysqld.sock
      username: #{db_user}
      password: #{db_password}
      reconnect: true

    development:
      database: #{db_name_prefix}_development
      <<: *base

    test:
      database: #{db_name_prefix}_test
      <<: *base

    production:
      database: #{db_name_prefix}_production
      <<: *base
    
    staging:
      database: #{db_name_prefix}_staging
      <<: *base
    EOF

    run "mkdir -p #{shared_path}/config"
    put db_config.result, "#{shared_path}/config/mongoid.yml"
  end
end

namespace :delayed_job do
  def rails_env
    fetch(:rails_env, false) ? "RAILS_ENV=#{fetch(:rails_env)}" : ''
  end
  
  desc "Stop the delayed_job process"
  task :stop, :roles => :app do
    run "cd #{current_path};#{rails_env} script/delayed_job stop"
  end

  desc "Start the delayed_job process"
  task :start, :roles => :app do
    run "cd #{current_path};#{rails_env} script/delayed_job #{delayed_job_params} start"
  end

  desc "Restart the delayed_job process"
  task :restart, :roles => :app do
    # run "cd #{current_path};#{rails_env} script/delayed_job restart"
    # stop
    # start
    run "cd #{current_path};#{rails_env} script/delayed_job stop && #{rails_env} script/delayed_job #{delayed_job_params} start"
  end
end

namespace :daemons do
  def rails_env
    fetch(:rails_env, false) ? "RAILS_ENV=#{fetch(:rails_env)}" : ''
  end
  
  desc "Stop daemons"
  task :stop, :roles => :app do
    run "cd #{current_path}; #{rails_env} script/socks_checker stop; #{rails_env} script/seo_stats_collector stop"
  end
  
  desc "Start daemons"
  task :start, :roles => :app do
    run "cd #{current_path}; #{rails_env} script/socks_checker start; #{rails_env} script/seo_stats_collector start"
  end

  desc "Restart daemons"
  task :restart, :roles => :app do
    run "cd #{current_path}; #{rails_env} script/socks_checker restart; #{rails_env} script/seo_stats_collector restart"
  end
end

namespace :magent do
    task :start do
      run "export RAILS_ENV=#{rails_env}; cd #{current_path}; bundle exec magent -d -Q default -l #{current_path}/log -P #{current_path}/tmp/pids start; true"
    end

    task :restart do
      run "export RAILS_ENV=#{rails_env}; cd #{current_path}; bundle exec magent -d -Q default -l #{current_path}/log -P #{current_path}/tmp/pids restart; true"
    end

    task :stop do
      run "export RAILS_ENV=#{rails_env}; cd #{current_path}; bundle exec magent -d -Q default -l #{current_path}/log -P #{current_path}/tmp/pids stop; true"
    end
  end

after "deploy:update_code", "deploy:symlink_configs"
after "deploy:update_code", "deploy:smart_asset"
after "deploy:smart_asset", "deploy:restart"
#after "deploy:update_code", "deploy:migrate"
#after "deploy:update_code", "deploy:bundle:install"
after "deploy:setup", "deploy:create_shared_dirs"
after "deploy:setup", "deploy:create_log_files"
#after :deploy, "deploy:migrate"
