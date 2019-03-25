module Departure
	class Migration < ActiveRecord::Migration[5.2]
		def require_pt_osc!
			raise StandardError, 'pt-online-schema-change is required!' unless pt_osc_available? || !Rails.env.production?
		end

		def connection_config
			@_connection_config ||= ActiveRecord::Base.connection_config.merge(adapter: 'percona')
		end

		def handler
			@_handler ||= ActiveRecord::ConnectionAdapters::ConnectionHandler.new
		end

		def connection_pool
			@_connection ||= handler.establish_connection(connection_config)
		end

		def pt_osc_available?
			`which pt-online-schema-change`.present?
		end

		# Execute this migration in the named direction
		def migrate(direction)
			unless pt_osc_available?
				announce 'no pt-osc available, using default migrator'
				super
				return
			end

			return unless respond_to?(direction)

			case direction
			when :up   then announce 'migrating'
			when :down then announce 'reverting'
			end

			time = nil

			connection_pool.with_connection do |conn|
				time = Benchmark.measure do
					exec_migration(conn, direction)
				end
			end

			case direction
			when :up   then announce 'migrated (%.4fs)' % time.real; write
			when :down then announce 'reverted (%.4fs)' % time.real; write
			end
		end
	end
end
