Pod::Spec.new do |s|
  s.name             = 'IlkerSevimNetworking'
  s.version          = '1.0.0'
  s.summary          = 'URLSession networking with retry, idempotent POST, and token refresh.'
  s.description      = <<-DESC
    Foundation-only Swift networking helpers: typed requests, retry policy
    (backoff, jitter, Retry-After), idempotency-key gated POST retries,
    one-shot 401 token refresh, and redacted logging.
  DESC
  s.homepage         = 'https://github.com/redjadet/ilkersevim_networking'
  s.license          = { :type => 'Apache-2.0', :file => 'LICENSE' }
  s.author           = { 'İlker Sevim' => 'ilkersevim2007@gmail.com' }
  s.source           = {
    :git => 'https://github.com/redjadet/ilkersevim_networking.git',
    :tag => s.version.to_s
  }
  s.swift_versions   = ['5.9']
  s.ios.deployment_target = '17.0'
  s.osx.deployment_target = '14.0'
  s.watchos.deployment_target = '10.0'
  s.source_files     = 'Sources/IlkerSevimNetworking/**/*.swift'
  s.frameworks       = 'Foundation'
  s.ios.frameworks   = 'Security'
  s.osx.frameworks   = 'Security'
end
