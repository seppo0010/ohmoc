Pod::Spec.new do |s|
  s.name             = "ohmoc"
  s.version          = "0.1.0"
  s.summary          = "Object-hash mapping library for rlite"
  s.description      = <<-DESC
                       Ohmoc is a library for storing objects in rlite,
                       a persistent key-value database.
                       DESC
  s.homepage         = "https://github.com/seppo0010/ohmoc"
  s.license          = 'MIT'
  s.author           = { "Sebastian Waisbrot" => "seppo0010@gmail.com" }
  s.source           = { :git => "https://github.com/seppo0010/ohmoc.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'

  s.public_header_files = 'Pod/Classes/**/*.h'
  s.dependency 'objc-rlite', '~> 0.1.6'
  s.dependency 'msgpack', '~> 0.1.3'
end
