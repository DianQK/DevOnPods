platform :ios, '9.0'

target 'AwesomeProject' do
  use_frameworks!
  pod 'UMengAnalytics-NO-IDFA', '~> 4.2'
  framework_pods = []
  framework_pods = ENV['FRAMEWORK_PODS'].split(",") if ENV['FRAMEWORK_PODS']
  development = false
  development = ENV['PODFILE_TYPE'] == 'development' if ENV['PODFILE_TYPE']
  build_pods = []
  build_pods = ENV['BUILD_PODS'].split(",") if ENV['BUILD_PODS']
  build_all = true # dev 下忽略 build all 参数
  if ENV['PODFILE_TYPE'] == 'generate_frameworks'
    build_all = build_pods.length == 0 # 等于 0 则 build all
    Pod::UI.puts "Build all" if build_all
    Pod::UI.puts "Build include #{build_pods}" if !build_all
  end
  if (development || framework_pods.include?('Then')) || !(build_pods.include?('Then') || build_all)
    pod 'AwesomeProject/Then', :path => "./"
  else
    pod 'Then', '~> 2.1'
  end
  if (development || framework_pods.include?('SwiftyJSON')) || !(build_pods.include?('SwiftyJSON') || build_all)
    pod 'AwesomeProject/SwiftyJSON', :path => "./"
  else
    pod 'SwiftyJSON', '~> 3.1'
  end
  if (development || framework_pods.include?('AwesomeModule')) || !(build_pods.include?('AwesomeModule') || build_all)
    pod 'AwesomeProject/AwesomeModule', :path => "./"
  else
    pod 'AwesomeModule', :path => './'
  end
end

post_install do |installer|
  generate_frameworks installer if ENV['PODFILE_TYPE'] == 'generate_frameworks'
  generate_module installer
end

def generate_frameworks (installer)
  Pod::UI.puts "Building dependencies"
  project = installer.pods_project # Project.new(installer.sandbox.project_path)
  project.recreate_user_schemes(:visible => true)
  project.save
  project.targets.each do |target|
    Xcodeproj::XCScheme.share_scheme(installer.sandbox.project_path, target)
  end
  carthage_build_log = `carthage build --no-skip-current --configuration Release --platform iOS --project-directory #{installer.sandbox.root}`
  Pod::UI.puts carthage_build_log
end

def generate_module (installer)
  sandbox_root = Pathname(installer.sandbox.root)
  sandbox = Pod::Sandbox.new(sandbox_root)
  module_workaround_root = sandbox_root.parent + 'PodsModuleWorkaround'
  frameworks = []
  installer.pod_targets.each do |umbrella|
    umbrella.specs.each do |spec|
      consumer = spec.consumer(umbrella.platform.name)
      pod_dir = sandbox.pod_dir(spec.root.name)
      if pod_dir.exist? # 本地 pod 不存在这个目录
        file_accessor = Pod::Sandbox::FileAccessor.new(sandbox.pod_dir(spec.root.name), consumer)
        frameworks += file_accessor.vendored_frameworks
      end
    end
  end
  frameworks.each do |framework|
    destination = framework
    root = module_workaround_root + framework.basename + 'Modules'
    if root.exist?
      Pod::UI.puts "Copying #{root} to #{destination}"
      FileUtils.cp_r root, destination, :remove_destination => true
    end
  end
end
