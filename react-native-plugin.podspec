require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-plugin"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.description  = <<-DESC
                    react-native-plugin
                   DESC
  s.homepage     = "https://github.com/Bluedot-Innovation/PointSDK-iOS"
  s.license = {
    :type => 'Copyright',
    :text => <<-LICENSE
    Point SDK
    Created by Bluedot Innovation in 2019.
    Copyright © 2019 Bluedot Innovation. All rights reserved.
    By downloading or using the Bluedot Point SDK for iOS, You agree to the Bluedot Terms and Conditions
    https://bluedot.io/agreements/#terms and Privacy Policy https://bluedot.io/agreements/#privacy
    and Billing Policy https://bluedot.io/agreements/#billing
    and acknowledge that such terms govern Your use of and access to the iOS SDK.
    LICENSE
  }
  s.author        = { "Bluedot Innovation" => "https://www.bluedot.io" }
  s.platform      = :ios, '10.0'
  s.swift_version = '5.0'
  s.source       = { :git => "https://github.com/Bluedot-Innovation/Bluedot-React-Native-Plugin.git" }

  s.source_files  = "ios/**/*.{h,m,swift}"
  s.requires_arc  = true

  s.dependency "BluedotPointSDK"
  s.dependency "React"
end

