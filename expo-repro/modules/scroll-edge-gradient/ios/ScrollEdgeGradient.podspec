Pod::Spec.new do |s|
  s.name           = 'ScrollEdgeGradient'
  s.version        = '1.0.0'
  s.summary        = 'Source-separated scroll-edge gradients for Expo'
  s.description    = 'A local Expo module demonstrating a Metal gradient behind native scroll content.'
  s.author         = ''
  s.homepage       = 'https://github.com/thisislvca/scroll-edge-gradient-repro'
  s.platforms      = {
    :ios => '16.4',
    :tvos => '16.4'
  }
  s.source         = { git: '' }
  s.static_framework = true

  s.dependency 'ExpoModulesCore'

  # Swift/Objective-C compatibility
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
  }

  s.source_files = "**/*.{h,m,mm,swift,hpp,cpp}"
end
