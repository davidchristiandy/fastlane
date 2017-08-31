module Gym
  class Xcode
    class << self
      def xcode_path
        Helper.xcode_path
      end

      def xcode_version
        Helper.xcode_version
      end

      # Below Xcode 7 (which offers a new nice API to sign the app)
      def pre_7?
        UI.user_error!("Unable to locate Xcode. Please make sure to have Xcode installed on your machine") if xcode_version.nil?
        v = xcode_version
        is_pre = v.split('.')[0].to_i < 7
        is_pre
      end

      def legacy_api_deprecated?
        UI.user_error!("Unable to locate Xcode. Please make sure to have Xcode installed on your machine") if xcode_version.nil?
        v = xcode_version
        Gem::Version.new(v) >= Gem::Version.new('8.3.0')
      end
    end
  end
end
