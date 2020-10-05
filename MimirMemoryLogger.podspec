Pod::Spec.new do |s|
  s.name             = 'MimirMemoryLogger'
  s.version          = '0.2.0'
  s.summary          = 'MimirMemoryLogger is a framework that takes snapshots of the iOS device`s heap and logs them to disk for later debugging.'
  s.description      = <<-DESC
MimirMemoryLogger is a framework that takes snapshots of the iOS device's heap and logs them to disk for later debugging. This was created to make debugging memory issues easier when the device is not connected to Xcode.
The snapshot json files can be used by a python script included in this repo's github page that prettifies the results and sorts memory instances accordingly. 
                       DESC

  s.homepage         = 'https://github.com/amereid/MimirMemoryLogger'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'amereid' => 'amereid92@gmail.com' }
  s.source           = { :git => 'https://github.com/amereid/MimirMemoryLogger.git', :tag => s.version.to_s }

  s.swift_versions = '5.0'
  s.ios.deployment_target = '10.0'
  s.source_files = 'MimirMemoryLogger/Classes/**/*'
end
