platform :ios, '13.0'

target 'EventAdmissionSample' do
  use_frameworks!

  # Pods for EventAdmissionSample
  pod 'Ver-ID', '2.3.2'

  post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
    end
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings.delete 'BUILD_LIBRARY_FOR_DISTRIBUTION'
      end
    end
  end
end
