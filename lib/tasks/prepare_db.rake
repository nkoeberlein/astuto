# Prepares the database when a container starts (docker-entrypoint.sh): loads the schema and
# seeds on a fresh database, migrates otherwise. Several containers may start at once (web and
# worker, or replicas in Kubernetes), so a Postgres advisory lock lets only one of them work; the
# others wait and then find nothing left to do. The lock lives on its own connection, because
# db:schema:load reconnects ActiveRecord.
namespace :astuto do
  desc 'Load the schema and seed (fresh database) or migrate, one container at a time'
  task prepare_db: :environment do
    lock_id = 727_274_001
    config = ActiveRecord::Base.connection_db_config.configuration_hash
    lock = if config[:url].present?
      PG.connect(config[:url])
    else
      PG.connect(host: config[:host], port: config[:port], user: config[:username], password: config[:password], dbname: config[:database])
    end

    begin
      lock.exec("SELECT pg_advisory_lock(#{lock_id})")
      fresh = !ActiveRecord::Base.connection.table_exists?('schema_migrations') ||
        ActiveRecord::Base.connection.select_value('SELECT COUNT(*) FROM schema_migrations').to_i.zero?

      if fresh
        puts 'Fresh database: loading schema and seeds...'
        Rake::Task['db:schema:load'].invoke
        Rake::Task['db:seed'].invoke
      else
        Rake::Task['db:migrate'].invoke
      end
    ensure
      lock.exec("SELECT pg_advisory_unlock(#{lock_id})") rescue nil
      lock.close
    end
  end
end
