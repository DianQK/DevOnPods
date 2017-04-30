Pod::Spec.new do |s|
  s.name             = "AwesomeProject"
  s.version          = "1"
  s.summary          = "Use Pods Demo"
  s.homepage         = "https://github.com/DianQK/DevOnPods"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "DianQK" => "dianqk@icloud.com" }
  s.source           = { :git => "https://github.com/DianQK/DevOnPods.git",
                         :tag => s.version.to_s }
  s.ios.deployment_target = "8.0"
  # s.vendored_frameworks = ["Pods/Carthage/Build/iOS/Then.framework", "Pods/Carthage/Build/iOS/SwiftyJSON.framework"]
  ['Then', 'SwiftyJSON', 'AwesomeModule'].each do |name|
    s.subspec name do |sp|
      sp.vendored_frameworks = "Pods/Carthage/Build/iOS/#{name}.framework"
    end
  end

end


# Pod::Spec.new do |s|
#   s.name             = "Then"
#   s.version          = "2.1.0"
#   s.summary          = "Super sweet syntactic sugar for Swift initializers."
#   s.homepage         = "https://github.com/devxoul/Then"
#   s.license          = { :type => "MIT", :file => "LICENSE" }
#   s.author           = { "Suyeol Jeon" => "devxoul@gmail.com" }
#   s.source           = { :git => "https://github.com/devxoul/Then.git",
#                          :tag => s.version.to_s }
#   s.source_files     = "Sources/*.swift"
#   s.requires_arc     = true
#
#   s.ios.deployment_target = "8.0"
#   s.osx.deployment_target = "10.9"
#   s.tvos.deployment_target = "9.0"
# end
