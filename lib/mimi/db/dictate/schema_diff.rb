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
        # @return [Hash] :columns, :indexes => :from, :to
        #
        def self.diff(from, to, opts = {})
          options = DEFAULT_OPTIONS.merge(opts)
          result = { table_name: from.table_name, columns: {}, indexes: {} }
          all_column_names = (from.columns.values.map(&:name) + to.columns.values.map(&:name)).uniq
          all_column_names.each do |c|
            if from.columns[c] && to.columns[c].nil?
              result[:columns][c] = { from: from.columns[c], to: nil }
            elsif from.columns[c] && to.columns[c] && !(from.columns[c] == to.columns[c])
              result[:columns][c] = { from: from.columns[c], to: to.columns[c] }
            elsif from.columns[c].nil? && to.columns[c]
              result[:columns][c] = { from: nil, to: to.columns[c] }
            end
          end
          from_indexes = from.indexes.map { |i| [i.columns, i] }.to_h
          to_indexes   = to.indexes.map { |i| [i.columns, i] }.to_h
          all_index_cols = (from_indexes.keys + to_indexes.keys).uniq
          all_index_cols.each do |cc|
            if from_indexes[cc] && to_indexes[cc].nil?
              result[:indexes][cc] = { from: from_indexes[cc], to: nil }
            elsif from_indexes[cc] && to_indexes[cc]
              # index diff is not supported
            elsif from_indexes[cc].nil? && to_indexes[cc]
              result[:indexes][cc] = { from: nil, to: to_indexes[cc]}
            end
          end

          result
        end
      end # module SchemaDiff
    end # module Dictate
  end # module DB
end # module Mimi
