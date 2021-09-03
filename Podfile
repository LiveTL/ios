abstract_target 'livetl' do
  use_frameworks!
  inhibit_all_warnings!

  target 'ios' do
    platform :ios, '14.0'

    #pod 'common', :git => 'https://github.com/livetl/common'

    pod 'Eureka'
    pod 'FontBlaster'
    pod 'Kingfisher'
    pod 'Neon'
    pod 'SCLAlertView'
    pod 'NotificationBannerSwift', '~> 3.0.0'
    pod 'XCDYouTubeKit', :git => 'https://github.com/Candygoblen123/XCDYouTubeKit', :branch => 'master'
    pod 'RxCocoa'
    pod 'RxDataSources'
    pod 'RxFlow'
    pod 'RxSwift'
    pod 'SwiftDate'
    pod 'SwiftyUserDefaults'
    pod 'M3U8Kit'
    pod 'FontAwesome.swift'
    pod 'RxCombine'

    pod 'FLEX', :configuration => 'DEBUG'
    
    target 'iosUnitTests' do
      inherit! :complete
    end
  end
end
