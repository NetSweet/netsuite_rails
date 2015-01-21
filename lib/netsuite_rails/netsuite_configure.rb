# opinionated configuration

NetSuite.configure do
  reset!
  
  email         ENV['NETSUITE_EMAIL']     if ENV['NETSUITE_EMAIL'].present?
  password      ENV['NETSUITE_PASSWORD']  if ENV['NETSUITE_PASSWORD'].present?
  account       ENV['NETSUITE_ACCOUNT']   if ENV['NETSUITE_ACCOUNT'].present?
  role          ENV['NETSUITE_ROLE']      if ENV['NETSUITE_ROLE'].present?
  api_version   ENV['NETSUITE_API']       if ENV['NETSUITE_API'].present?
  sandbox       (ENV['NETSUITE_PRODUCTION'].blank? || ENV['NETSUITE_PRODUCTION'] != 'true')

  read_timeout  100000
end
