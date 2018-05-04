# frozen_string_literal: true

module Mimi
  module DB
    module Dictate
      module SchemaDiff
        DEFAULT_OPTIONS = {
          # Force updates on fields defined as :primary_key type.
          # If disabled, the field definition will only be used in 'CREATE TABLE'.
          # (forced updates on :primary_key break on Postgres, at least)
          #
          force_primary_key: false
        }.freeze

        #
        # Compares two schema definitions
        #
        # @return [Hash] :columns, :indexes => :add, :remove, :change
        #
        def self.diff(from, to, opts = {})
          options = DEFAULT_OPTIONS.merge(opts)
          from_column_names = from.columns.values.map(&:name)
          to_column_names = to.columns.values.map(&:name)
          columns_names_remove = from_column_names - to_column_names
          columns_names_add    = to_column_names - from_column_names
          columns_add          = to.columns.values.select do |c|
            columns_names_add.include?(c.name)
          end
          columns_change       = to.columns.values.reject do |c|
            res = from.columns[c.name].nil? || from.columns[c.name] == c
            res ||= c.type == :primary_key unless options[:force_primary_key]
          end
          from_indexes_c = from.indexes.map(&:columns).uniq
          to_indexes_c = to.indexes.map(&:columns).uniq
          # ignore primary key indexes
          from_indexes_c -= [[from.primary_key&.name]]
          to_indexes_c -= [[to.primary_key&.name]]

          indexes_c_remove = from_indexes_c - to_indexes_c
          indexes_c_add = to_indexes_c - from_indexes_c
          indexes_remove = from.indexes.select do |idx|
            indexes_c_remove.include?(idx.columns)
          end
          indexes_add    = to.indexes.select do |idx|
            indexes_c_add.include?(idx.columns)
          end

          diff = {}
          unless columns_names_remove.empty?
            diff[:columns] ||= {}
            diff[:columns][:remove] = columns_names_remove
          end
          unless columns_change.empty?
            diff[:columns] ||= {}
            diff[:columns][:change] = columns_change
          end
          unless columns_add.empty?
            diff[:columns] ||= {}
            diff[:columns][:add] = columns_add
          end
          unless indexes_remove.empty?
            diff[:indexes] ||= {}
            diff[:indexes][:remove] = indexes_remove
          end
          unless indexes_add.empty?
            diff[:indexes] ||= {}
            diff[:indexes][:add] = indexes_add
          end
          diff
        end
      end # module SchemaDiff
    end # module Dictate
  end # module DB
end # module Mimi
