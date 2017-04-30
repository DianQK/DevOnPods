Pod::Spec.new do |s|
  s.name             = "AwesomeModule"
  s.version          = "1.0.0"
  s.summary          = "Super sweet syntactic sugar for Swift initializers."
  s.homepage         = "https://github.com/devxoul/Then"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "DianQK" => "devxoul@gmail.com" }
  s.source           = { :git => "https://github.com/DianQK/DevOnPods.git",
                         :tag => s.version.to_s }
  s.source_files     = "AwesomeModule/AwesomeModule/*.swift"

  s.ios.deployment_target = "8.0"
end
