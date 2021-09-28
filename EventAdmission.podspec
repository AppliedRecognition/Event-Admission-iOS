Pod::Spec.new do |spec|

  spec.name         = "EventAdmission"
  spec.version      = "1.0.0"
  spec.summary      = "iOS framework that facilitates admitting attendees to events"
  spec.homepage     = "https://github.com/AppliedRecognition/Event-Admission-iOS"
  spec.license      = "MIT"
  spec.author       = "Jakub Dolejs"
  spec.platform     = :ios, "13.0"
  spec.source       = { :git => "https://github.com/AppliedRecognition/Event-Admission-iOS.git", :tag => "v#{spec.version}" }
  spec.source_files = "EventAdmission/**/*.{swift,xcdatamodeld,docc}"
  spec.resource_bundles = { "EventAdmissionResources" => ["EventAdmission/*.xib"] }

end
