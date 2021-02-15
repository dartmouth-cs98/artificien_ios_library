#
# Be sure to run `pod lib lint Artificien.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ArtificienLibrary'
  s.version          = '0.1.0'
  s.summary          = 'A federated learning library used to connect to the Artificien platform.'
  s.swift_version    = '5.3'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
This is a federated learning library used to connect to the Artificien platform. Use it to download and train the data science models that need access to your app's local data.
                       DESC

  s.homepage         = 'https://github.com/dartmouth-cs98/artificien_ios_library'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'shreyas.v.agnihotri@gmail.com' => 'shreyas.v.agnihotri@gmail.com' }
  s.source           = { :git => 'https://github.com/dartmouth-cs98/artificien_ios_library.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'

  s.source_files = 'Artificien/Classes/**/*'
  
  # s.resource_bundles = {
  #   'Artificien' => ['Artificien/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  s.static_framework = true
  s.platform = :ios, "13.0"
  s.dependency 'OpenMinedSwiftSyft', '~> 0.1.3-beta2'
  s.dependency 'Alamofire', '~> 4.7'
  
end
