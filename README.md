# DevOnPods

- 将 UMeng 支持 module .
- 同一 target 环境切换
- Plugin
- 基于 CocoaPods 开发

在阅读本文前，请谨记 `Podfile` 是一段 Ruby 代码（如果您对 Ruby 有一点语法上的了解，这将会非常有帮主，笔者有着一年前的看了 2 小时的 Ruby 基础还是够的），这对于我们定制以下的需求将非常有帮助。


## CocoaPods Plugin

标准的 CocoaPods 有时不能完全满足我们需求，这时候我们可能要考虑加一些插件了。而这些插件的类型主要有两种：

- Hook `pre_install` 和 `post_install` ，然后搞事情
- 添加一些额外的命令，如 `pod try Alamofire`

先来看一下 `pod install` 都做了什么，以 `AwesomeProject` 为例，我在 `Podfile` 加入了 `Then` 这个第三方库：

```ruby
# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'AwesomeProject' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for AwesomeProject
  pod 'Then', '~> 2.1'

end
```

执行 `pod install --verbose` 得到如下输出：

```

Preparing
    - Running pre install hooks

Analyzing dependencies

Inspecting targets to integrate
  Using `ARCHS` setting to build architectures of target `Pods-AwesomeProject`: (``)

Finding Podfile changes
  - Then

Resolving dependencies of `Podfile`

Comparing resolved specification to the sandbox manifest
  - Then

Downloading dependencies

-> Using Then (2.1.0)
  - Running pre install hooks

Generating Pods project
  - Creating Pods project
  - Adding source files to Pods project
  - Adding frameworks to Pods project
  - Adding libraries to Pods project
  - Adding resources to Pods project
  - Linking headers
  - Installing targets
    - Installing target `Then` iOS 8.0
      - Generating Info.plist file at `Pods/Target Support Files/Then/Info.plist`
      - Generating module map file at `Pods/Target Support Files/Then/Then.modulemap`
      - Generating umbrella header at `Pods/Target Support Files/Then/Then-umbrella.h`
    - Installing target `Pods-AwesomeProject` iOS 9.0
      - Generating Info.plist file at `Pods/Target Support Files/Pods-AwesomeProject/Info.plist`
      - Generating module map file at `Pods/Target Support Files/Pods-AwesomeProject/Pods-AwesomeProject.modulemap`
      - Generating umbrella header at `Pods/Target Support Files/Pods-AwesomeProject/Pods-AwesomeProject-umbrella.h`
  - Running post install hooks
  - Writing Xcode project file to `Pods/Pods.xcodeproj`
    - Generating deterministic UUIDs
  - Writing Lockfile in `Podfile.lock`
  - Writing Manifest in `Pods/Manifest.lock`

Integrating client project

Integrating target `Pods-AwesomeProject` (`AwesomeProject.xcodeproj` project)
  - Running post install hooks
    - cocoapods-stats from `/usr/local/lib/ruby/gems/2.4.0/gems/cocoapods-stats-1.0.0/lib/cocoapods_plugin.rb`

Sending stats
      - Then, 2.1.0

-> Pod installation complete! There is 1 dependency from the Podfile and 1 total pod installed.
```

整个流程大概如下：

- Preparing 做一些准备工作，主要是下载第三方库的代码
- Running pre install hooks 执行 `pre_install`
- Generating Pods project 创建 Pods 工程
- 处理所有 Pod 需要做的事情，比如添加 frameworks 、资源文件
- Running post install hooks 执行 `post_install`
- Integrating client project 集成到主工程中

`pre_install` 和 `post_install` 都可以写到我们的 `Podfile` 中。

其中的各种参数和属性您可以从 http://www.rubydoc.info/gems/cocoapods/ 中找到，需要注意的是 `pre_install` 中可能获取不到 `pod_project` 等信息，第一次 pod 时是没有 Pods 工程的。

那么我们可以在这里做些什么呢，有一个最常见的是设置 Swift 版本：

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end
```

在这里我们遍历了 Pods 工程中的所有 Target ，设置 Swift 版本为 3.0 。需要注意的是，CocoaPods 是执行完 `post_install` 才生成 Project ，在这一步可能获取不到 Pods 工程的文件。

## 打 Log

在 CocoaPods 中输出一些内容有两种方式，直接调用 `puts` ，这只会在 `--verbose` 下看到输出结果。
调用 `Pod::UI.puts` 则会在所有场景下有输出结果。

那么我们是不是也可以在这里进行一些文件操作呢？当然可以，我们可以在 Umeng 的 modulemap 文件。

以下代码供参考：

```ruby
post_install do |installer|
  sandbox_root = Pathname(installer.sandbox.root)
  sandbox = Pod::Sandbox.new(sandbox_root)
  module_workaround_root = sandbox_root + 'ModuleWorkaround'
  frameworks = []
  installer.pod_targets.each do |umbrella|
    umbrella.specs.each do |spec|
      consumer = spec.consumer(umbrella.platform.name)
      file_accessor = Pod::Sandbox::FileAccessor.new(sandbox.pod_dir(spec.root.name), consumer)
      frameworks += file_accessor.vendored_frameworks
    end
  end
  frameworks.each do |framework|
    destination = framework
    root = module_workaround_root + framework.basename + 'Modules'
    Pod::UI.puts "Copying #{root} to #{destination}"
    FileUtils.cp_r root, destination, :remove_destination => true
  end
end
```

上述是将 `Pods/ModuleWorkaround` 的 `module.modulemap` 拷贝到对应的 framework 中。这样一来每当 Umeng 更新了 SDK 后，我们都不需要再修改一份 Podspec 了。此外我们还可以将这个封装成一个 Plugin 使用。这就是 Plugin 的一种类型，Hook 安装前和安装后实际做一些额外的操作。

CocoaPods 中已有的一些插件就是采用 Hook 的方法：

- [Rome](https://github.com/CocoaPods/Rome) 不对主工程进行修改，创建 Pods 工程，并生成所有 framworks 到 Rome 目录。
- [cocoapods-keys](https://github.com/orta/cocoapods-keys) 为工程添加安全设置各种 Key 的支持，当接入一些服务时，我们需要使用对应的 AppKey 之类的东西，cocoapods-keys 会将这些 key 保存到 Keychain 中。这个插件属于比较实用的了，此外您可以阅读一下源码，这个的实现方式非常有趣，它通过 Hook `pre_install` ，在这里增加一个新的 Pod `Keys` ，这个 `Keys` 中保存了所有的 AppKey 。

另外一种添加 Pod 命令的也有一些实用的插件：

- [cocoapods-deintegrate](https://github.com/CocoaPods/cocoapods-deintegrate) 移除 Pod
- [cocoapods-deploy](https://github.com/jcampbell05/cocoapods-deploy) 加快 `pod install`

## 基于 CocoaPods 开发

随着工程变得越来越大，或者是您选择了 Swift ，都会遇到编译时间较长的问题，特别是在选择 Swift 后。

像美团这样大的工程，基本就是采用这个方案，但作为一个小团队，又选择了 Swift ，那就没有时间去构建一套完整的二进制化代码流程了。

笔者在这里找到了还算好用的解决方案。先来谈一下思路：

笔者原本是打算在 `pre_install` 中搞事情的，将所有的源码形式的 Swift 第三方库全部编译成 framework ，并设置好对应的 `vendored_frameworks` 。然而笔者依靠着 2 小时的 Ruby 水平，翻看了部分源码和 RubyDoc 对应一些 API 文档，还带着看了一些插件的源码，基本是一无所获。

但也不完全是一无所有，事实上，在 project 引入一个 framework ，主要是配置一下 `Build Setting` 的 `Framework Search Paths` ，把对应的 framework 拷贝到运行的 App 中。您可以尝试沿着这个思路完成二进制化的需求。按照这个方案完成的话，我们应当是不需要任何额外的 podspec 了。

那我们退而求其次，创建本地的 podspec ，并引用对应的 framework 。

那么现在的首要解决的问题是，如何创建 framework 。我们可以使用 xcodebuild ，类似 [Rome](https://github.com/CocoaPods/Rome) 的方案。直接使用 xcodebuild 需要写各种各样的参数，我们可以考虑使用 Carthage 或者 Fastlane 的 GYM 。

这里我们使用 Carthage 完成这个需求，用 Carthage 可以直接生成 framework 和 dSYM。（当然我们不能去写一个 Cartfile 去拉代码了，我们可以直接 build Pods project）。使用 `carthage build --no-skip-current` 即可。

那么此时遇到了一个问题，share scheme 。原本这应该是一个很简单的事情，直接将 `xcuserdata` 中的 scheme 移到 `xcshareddata` 即可，但 `post_install` 这里可能还没有生成 scheme 。

CocoaPods 提供了 Xcodeproj 工具，我们可以使用它来修改 project 。在 `pre_install` 中我们可以直接获取到 Pods 工程 `installer.pods_project` 。

```ruby
def generate_frameworks (installer)
  project = installer.pods_project # Project.new(installer.sandbox.project_path)
  project.recreate_user_schemes(:visible => true)
  project.save
  project.targets.each do |target|
    Xcodeproj::XCScheme.share_scheme(installer.sandbox.project_path, target)
  end
  carthage_build_log = `carthage build --no-skip-current --configuration Release --platform iOS --project-directory #{installer.sandbox.root}`
  Pod::UI.puts carthage_build_log
end
```

为了方便后面的使用，我在这里创建了一个方法。

创建 scheme ，share scheme ，最后 build 一下。调用了 `generate_frameworks` 后，Pods 目录下就会增加对应的 `Carthage` 文件夹。打包出 framework 到这里就完成了。

接下来再去创建一个本地的 `Then.podspec` 即可。podspec 貌似只能读取当前目录，所以我将它放到了 `Pods/Carthage` 目录下：

```ruby
Pod::Spec.new do |s|
  s.name             = "Then"
  s.version          = "2.1.0"
  s.summary          = "Super sweet syntactic sugar for Swift initializers."
  s.homepage         = "https://github.com/devxoul/Then"
  # s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "Suyeol Jeon" => "devxoul@gmail.com" }
  s.source           = { :git => "https://github.com/devxoul/Then.git",
                         :tag => s.version.to_s }
  # s.source_files     = "Sources/*.swift"
  # s.requires_arc     = true
  s.vendored_frameworks = "Build/iOS/#{s.name}.framework"

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.tvos.deployment_target = "9.0"
end
```

虽然我们创建了本地的 podspec ，但当我们更新了某个依赖的版本时，一版我们也无需修改对应的 podspec 。因为这里选择的 framework 是我们使用原 podspec build 出来的 framework 。

最终我们的 Podfile 大概长这个样子：

```ruby
platform :ios, '9.0'

target 'AwesomeProject' do
  use_frameworks!
  pod 'UMengAnalytics-NO-IDFA', '~> 4.2'
  case ENV['PODFILE_TYPE']
  when 'development'
    pod 'Then', :path => "./Pods/Carthage"
  else
    pod 'Then', '~> 2.1'
  end
end

post_install do |installer|
  generate_frameworks installer if ENV['PODFILE_TYPE'] == 'generate_frameworks'
  generate_module installer
end
```

当选择不加任何环境参数时，第三方库使用的是源码，当使用参数 `generate_frameworks` 则 build 出对应的 framework 。当使用参数 `development` 时，则直接使用之前打包的 framework 。

这样一来我们就没有 clean 2 分钟，扯淡（编译）2 小时的事情了。但在开发时，我们可能又需要调试的需求，好在 CocoaPods 即将支持 `dSYM` 的设置。您可以在 [Issues 1698](https://github.com/CocoaPods/CocoaPods/issues/1698) 中了解更多。

本文大部分的内容都已经完成，最后我们还可以做一些额外的事情再改进一下这个流程，以及一些额外的 Tip。

当基于上述情况开发时，我们的 `Podfile.lock` 会频繁地变动，我们可以考虑在 `Podfile` 做好版本控制，或者使用 [Danger](http://danger.systems) 监管 PR 中 `Podfile.lock` 的变动。关于 Danger 相关内容您可以从 [使用 Danger 提高 Code Review 体验](https://blog.dianqk.org/2017/02/28/use-danger/) 了解到基本内容。

上述方案中，可能有一些地方比较尴尬，我们将一些需要保留到 Git 中的文件放到了 Pods 中，写好 .gitignore 可以解决这个问题，但执行个 `rm -rf Pods`，顺便还 merge 到了主分支，这还是略尴尬了。

我们还可以考虑把这些移出来，放到项目的根目录中。但这样可能会在根目录有一堆的 podspec ，这有些不友好。但 podspec 中 `vendored_frameworks` 可以放数组啊。
