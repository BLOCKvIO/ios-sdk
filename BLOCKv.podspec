Pod::Spec.new do |s|
  s.name                  = 'BLOCKv'
  s.version               = '4.0.0'
  s.summary               = 'The BLOCKv SDK allows you to easily integrate your apps into the BLOCKv Platform.'
  s.homepage              = 'https://blockv.io'
  s.license               = { :type => 'BLOCKv AG', :file => 'LICENSE' }
  s.author                = { 'BLOCKv' => 'developer.blockv.io' }
  s.source                = { :git => 'https://github.com/BLOCKvIO/ios-sdk.git', :tag => s.version.to_s }
  s.social_media_url      = 'https://twitter.com/blockv_io'
  s.ios.deployment_target = '11.0'
  s.swift_version         = '5.1'
  s.default_subspecs      = 'Face'
  
  s.subspec 'Core' do |s|
      s.source_files = 'Sources/Core/**/*.{swift}'
      s.dependency 'Alamofire',  '~> 4.9'     # Networking
      s.dependency 'Starscream', '~> 3.1'     # Web socket
      s.dependency 'JWTDecode',  '~> 2.4'     # JWT decoding
      s.dependency 'Signals',    '~> 6.0'     # Elegant eventing
      s.dependency 'SwiftLint',  '~> 0.39'    # Linter
      s.dependency 'GenericJSON', '~> 2.0'    # JSON
      s.dependency 'PromiseKit', '~> 6.13'    # Promises
      #s.exclude_files = '**/Info*.plist'
  end
  
  s.subspec 'Face' do |s|
      s.ios.source_files = 'Sources/Face/**/*.{swift}'
      s.dependency 'BLOCKv/Core'
      s.dependency 'FLAnimatedImage', '~> 1.0' # Gifs
      s.dependency 'Nuke',            '~> 8.4' # Image downloading
      #s.resource_bundles = {
      #    'FaceModule' => ['BlockV/Face/Face\ Views/**/*.{xib}']
      #}
      #s.exclude_files = "**/Info*.plist"
  end
  
end
