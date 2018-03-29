#
# Be sure to run `pod lib lint BlockV.podspec' to ensure this is a
# valid spec before submitting.
#

Pod::Spec.new do |s|
  s.name                  = 'BLOCKv'
  s.version               = '0.9.0'
  s.summary               = 'The BLOCKv SDK allows for easy integration into the BLOCKv Platform.'
  s.homepage              = 'https://blockv.io'
  s.license               = { :type => 'BLOCKv AG', :file => 'LICENSE' }
  s.author                = { 'BLOCKv' => 'developer.blockv.io' }
  s.source                = { :git => 'https://github.com/BLOCKvIO/ios-sdk.git', :tag => s.version.to_s }
  s.social_media_url      = 'https://twitter.com/blockv_io'
  s.ios.deployment_target = '10.0'
  s.source_files          = 'BlockV/Classes/**/*'
  
  s.dependency 'Alamofire', '~> 4.7'
end
