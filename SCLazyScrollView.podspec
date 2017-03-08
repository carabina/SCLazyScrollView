@version = "0.0.1"
Pod::Spec.new do |s|
    s.name         = "SCLazyScrollView"
    s.version      = @version
    s.summary      = "Lazy loading ScrollView for iOS (Swift3)"
    s.homepage     = "https://github.com/krazie99/SCLazyScrollView"
    s.license      = { :type => 'MIT', :file => 'LICENSE' }
    s.author       = { "Sean Choi" => "krazie99@gmail.com" }
    s.source       = { :git => "https://github.com/krazie99/SCLazyScrollView.git", :tag => @version }
    s.source_files = 'SCLazyScrollView/*.swift'
    s.requires_arc = true
    s.ios.deployment_target = '8.0'
end
