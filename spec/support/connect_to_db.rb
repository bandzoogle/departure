def connect_to_db(db_config)
  ActiveRecord::Base.establish_connection(
    adapter: 'mysql2',
    host: db_config['hostname'],
    username: db_config['username'],
    password: db_config['password'],
    database: db_config['database']
  )
end
