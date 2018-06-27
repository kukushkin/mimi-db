# frozen_string_literal: true

require 'sequel/adapters/postgres'

module Sequel
  #
  # A simplistic and not fully functional CockroachDB adapter
  #
  # TODO: to replace with a better alternative once available
  #
  module Cockroach
    class Database < Sequel::Postgres::Database
      set_adapter_scheme :cockroach
      set_adapter_scheme :cockroachdb

      # Cockroach DB only supports one savepoint
      def supports_savepoints?
        false
      end

      def server_version(*)
        80000 # mimics Postgres v8
        # 100000 # mimics Postgres v10
      end

      # Retrieves indexes for the given table
      #
      # NOTE: Apparently CockroachDB is not fully compatible with Postgres or Sequel's
      # Postgres adapter, and it can't correctly figure out indexes and their properties.
      # As a workaround, a specific #indexes() method is implemented here, which executes
      # `SHOW INDEXES FROM ...` and parses the results.
      #
      # @param table_name [String,Symbol]
      # @return [Hash] index_name => index_properties
      #
      def indexes(table_name)
        idxs = {}
        results = fetch('show indexes from ' + table_name.to_s).all
        results.each do |idx_entry|
          idx_name = idx_entry[:Name].to_sym
          next if idx_name == :primary # ignore primary index
          idxs[idx_name] ||= { name: idx_name.to_s }
          idx = idxs[idx_name]
          idx[:unique] = idx_entry[:Unique]
          idx[:deferrable] = false
          idx[:columns] ||= []
          idx[:columns] << idx_entry[:Column].to_sym unless idx_entry[:Implicit]
        end
        idxs
      end

      private

      def dataset_class_default
        Dataset
      end
    end

    class Dataset < Sequel::Postgres::Dataset
      def default_timestamp_format
        "'%Y-%m-%d %H:%M:%S%N%:z'"
      end
    end # class Dataset
  end # module Cockroach
end # module Sequel
