module ::MItamae
  module Plugin
    module Resource
      class AptKeyring < ::MItamae::Resource::Base
        define_attribute :action, default: :install
        define_attribute :name, type: String, default_name: true
        define_attribute :finger, type: String, default: nil
        define_attribute :keyserver, type: String, default: nil
        define_attribute :uri, type: String, default: nil

        self.available_actions = [:install, :remove]
      end
    end
  end
end
