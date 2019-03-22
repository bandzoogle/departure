require 'active_record'
require 'active_support/all'

require 'active_record/connection_adapters/for_alter'

require 'departure/version'
require 'departure/log_sanitizers/password_sanitizer'
require 'departure/runner'
require 'departure/cli_generator'
require 'departure/logger'
require 'departure/null_logger'
require 'departure/logger_factory'
require 'departure/configuration'
require 'departure/errors'
require 'departure/command'
require 'departure/connection_base'
require 'departure/migration'

require 'departure/railtie' if defined?(Rails)

# We need the OS not to buffer the IO to see pt-osc's output while migrating
$stdout.sync = true

module Departure
  cattr_accessor :loaded
  class << self
    attr_accessor :configuration
		def active?
			true
      # self.configuration.active?
    end
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  def self.unload
    return true unless ActiveRecord::Migrator.respond_to?(:original_run)

    ActiveRecord::Migrator.instance_eval do
      remove_method :run
      alias_method(:run, :original_run)
    end
    Departure.loaded = false
  end

  # Hooks Percona Migrator into Rails migrations by replacing the configured
  # database adapter
  def self.load
    return true if ActiveRecord::Migrator.respond_to?(:original_run)

    ActiveRecord::Migrator.class_eval do
      alias_method :original_run, :run
    
      def run
        migration = migrations.detect { |m| m.version == @target_version }
        if migration.nil? || ! migration.send(:load_migration).is_a?(Departure::Migration)
          original_run
        else
          run_without_lock
        end
      end
    end

    Departure.loaded = true
  end
end
