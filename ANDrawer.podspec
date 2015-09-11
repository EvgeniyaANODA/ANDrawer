Pod::Spec.new do |spec|
  spec.name     = 'ANDrawer'
  spec.version  = '1.0.5'
  spec.license  = { :type => 'MIT' }
  spec.homepage = 'https://github.com/anodamobi/ANDrawer'
  spec.authors  = { 'Oksana Kovalchuk' => 'oksana@anoda.mobi' }
  spec.summary  = 'AutoKeyboard handler for UIScrollViews'
  spec.source   = { :git => 'https://github.com/anodamobi/ANDrawer.git', :tag => spec.version.to_s }

  spec.source_files =  "ANDrawer/*.{h,m}"

  spec.public_header_files = "ANDrawer/*.h"

  spec.framework = "Foundation", "UIKit"
  spec.requires_arc = true

  spec.dependency 'ANHelperFunctions'
  spec.dependency 'pop'
  spec.dependency 'POP+MCAnimate', '~> 2.0'
  spec.dependency 'MSSPopMasonry'
  spec.dependency 'ReactiveCocoa', '~> 2.4'
  spec.dependency 'FrameAccessor', '~> 2.0'

  spec.ios.deployment_target = '7.0'
end
