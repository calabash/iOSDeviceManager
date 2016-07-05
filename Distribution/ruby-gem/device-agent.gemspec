Gem::Specification.new do |s|
  s.name        = 'device-agent'
  s.version     = `cat ../version.txt`.chomp()
  s.summary     = "DeviceAgent and associated utilities"
  s.description = "Tools for automated UI testing on iOS"
  s.authors     = ["Chris Fuentes", "Joshua Moody", "Jon Stoneman"] #?
  s.email       = 'chfuen@microsoft.com' #?
  s.executables << 'iOSDeviceManager'
  s.files       = Dir.glob("{bin,Frameworks,ipa,app}/**/*") + %w(LICENSE)
  s.license  = 'BSD 3-Clause'
end
