# opinionated configuration

NetSuite.configure do
  reset!
  
  email         ENV['NETSUITE_EMAIL']
  password      ENV['NETSUITE_PASSWORD']
  account       ENV['NETSUITE_ACCOUNT']
  role          ENV['NETSUITE_ROLE']
  api_version   ENV['NETSUITE_API']
  sandbox       (ENV['NETSUITE_PRODUCTION'].blank? || ENV['NETSUITE_PRODUCTION'] != 'true')

  read_timeout  100000
end
