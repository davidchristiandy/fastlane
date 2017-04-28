module Spaceship::TestFlight
  class Group < Base
    attr_accessor :id
    attr_accessor :name
    attr_accessor :is_default_external_group
    attr_accessor :is_internal_group

    attr_accessor :app_id

    attr_mapping({
      'id' => :id,
      'name' => :name,
      'isInternalGroup' => :is_internal_group,
      'appAdamId' => :app_id,
      'isDefaultExternalGroup' => :is_default_external_group
    })

    def self.all(app_id: nil)
      groups = client.get_groups(app_id: app_id)
      groups.map { |g| self.new(g) }
    end

    def self.find(app_id: nil, group_name: nil)
      groups = self.all(app_id: app_id)
      groups.find { |g| g.name == group_name }
    end

    def self.default_external_group(app_id: nil)
      groups = self.all(app_id: app_id)
      groups.find(&:default_external_group?)
    end

    def self.filter_groups(app_id: nil, &block)
      groups = self.all(app_id: app_id)
      groups.select(&block)
    end

    def self.internal_group(app_id: nil)
      groups = self.all(app_id: app_id)
      groups.find(&:internal_group?)
    end

    # First we need to add the tester to the app
    # It's ok if the tester already exists, we just have to do this... don't ask
    # This will enable testing for the tester for a given app, as just creating the tester on an account-level
    # is not enough to add the tester to a group. If this isn't done the next request would fail.
    # This is a bug we reported to the iTunes Connect team, as it also happens on the iTunes Connect UI on 18. April 2017
    def add_tester!(tester)
      # This post request makes the account-level tester available to the app
      tester_data = client.post_tester(app_id: self.app_id, tester: tester)
      # This put request adds the tester to the group
      client.put_tester_to_group(group_id: self.id, tester_id: tester_data['id'], app_id: self.app_id)
    end

    def remove_tester!(tester)
      client.delete_tester_from_group(group_id: self.id, tester_id: tester.tester_id, app_id: self.app_id)
    end

    def self.add_tester_to_groups!(tester: nil, app: nil, groups: nil)
      if tester.kind_of?(Spaceship::Tunes::Tester::Internal)
        self.internal_group(app_id: app.apple_id).add_tester!(tester)
      else
        self.perform_for_groups_in_app(app: app, groups: groups) { |group| group.add_tester!(tester) }
      end
    end

    def self.remove_tester_from_groups!(tester: nil, app: nil, groups: nil)
      if tester.kind_of?(Spaceship::Tunes::Tester::Internal)
        self.internal_group(app_id: app.apple_id).remove_tester!(tester)
      else
        self.perform_for_groups_in_app(app: app, groups: groups) { |group| group.remove_tester!(tester) }
      end
    end

    def default_external_group?
      is_default_external_group
    end

    def internal_group?
      is_internal_group
    end

    def self.perform_for_groups_in_app(app: nil, groups: nil, &block)
      if groups.nil?
        default_external_group = app.default_external_group
        if default_external_group.nil?
          UI.user_error!("The app #{app.name} does not have a default external group. Please make sure to pass group names to the `:groups` option.")
        end
        test_flight_groups = [default_external_group]
      else
        test_flight_groups = self.filter_groups(app_id: app.apple_id) do |group|
          groups.include?(group.name)
        end

        UI.user_error!("There are no groups available matching the names passed to the `:groups` option.") if test_flight_groups.empty?
      end

      test_flight_groups.each(&block)
    end
  end
end
