require "kiba"
require "kiba-common/dsl_extensions/show_me"
require "awesome_print"

require_relative "./bg_stat_export_json_reader"
require_relative "./sql_destination"

module BGstatBackupImporter
  module_function

  def etl(backup_file:, database:)
    pastel = Pastel.new
    Kiba.parse do
      extend Kiba::Common::DSLExtensions::ShowMe

      pre_process do
        database.create_table? :games do
          primary_key :id
          String :name
          String :bgg_id
          String :bg_stat_uuid
        end
      end

      pre_process do
        database[:games]
      end

      source BGStatExportJsonReader, file: backup_file, section: "games"

      transform do |row|
        if row["copies"].size > 0
          row["copies"] = row["copies"].map do |c|
            if c["metaData"]
              c["metaData"] = Oj.load(c["metaData"], symbol_key: true)
            end
            c
          end
        end
        row
      end

      transform do |row|
        if row["metaData"]
          row["metaData"] = Oj.load(row["metaData"], symbol_key: true)
        end
        row
      end

      destination SQLDestination,
        database: database,
        table_name: "games",
        on_error: ->(error, row) {
          puts pastel.red("Error inserting #{row}")
          puts error.inspect
        }
    end
  end
end
