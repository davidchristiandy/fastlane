require 'precheck/rule'
require 'precheck/rules/abstract_text_match_rule'

module Precheck
  class OtherPlatformsRule < AbstractTextMatchRule
    def self.key
      :other_platforms
    end

    def self.env_name
      "RULE_OTHER_PLATFORMS"
    end

    def self.friendly_name
      "No mentioning  competitors"
    end

    def self.description
      "mentioning other platforms, like Android or Blackberry"
    end

    def lowercased_words_to_look_for
      [
        "android",
        "windows phone",
        "tizen",
        "windows 10 mobile",
        "sailfish os",
        "windows universal app",
        "blackberry",
        "palm os",
        "symbian"
      ].map(&:downcase)
    end
  end
end
