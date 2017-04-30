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
  ['Then', 'SwiftyJSON'].each do |name|
    s.subspec name do |sp|
      sp.vendored_frameworks = "Pods/Carthage/Build/iOS/#{name}.framework"
    end
  end
end
