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
    ActiveRecord::Migrator.class_eval do
      remove_method :run
      alias_method(:run, :original_run)
    end
  end

  # Hooks Percona Migrator into Rails migrations by replacing the configured
  # database adapter
	def self.load
		unless ActiveRecord::Migrator.included_modules.include? MigratorPatch
			ActiveRecord::Migrator.send(:include, MigratorPatch)
		end
  end
end

module MigratorPatch
	def self.included(base)
		base.send(:include, InstanceMethods) unless base.included_modules.include? InstanceMethods
		base.class_eval do
			alias_method :original_run, :run unless defined?(:original_run)
			alias_method :run, :patched_run

			alias_method :original_migrate, :migrate unless defined?(:original_migrate)
			alias_method :migrate, :patched_migrate
		end
	end

	module InstanceMethods
		def patched_run
			binding.pry
			migration = migrations.detect { |m| m.version == @target_version }
			if migration.nil? || !migration.send(:load_migration).is_a?(Departure::Migration)
				original_run
			else
				run_without_lock
			end
		end

		def patched_migrate
			binding.pry
			# migration = migrations.detect { |m| m.version == @target_version }
			# if migration.nil? || !migration.send(:load_migration).is_a?(Departure::Migration)
			# 	original_migrate
			# else
			# 	migrate_without_lock
			# end

			if use_advisory_lock?
        with_advisory_lock { migrate_without_lock }
      else
        migrate_without_lock
			end
		end
	end
end
