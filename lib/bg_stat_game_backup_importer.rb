require "kiba"
require "kiba-common/dsl_extensions/show_me"
require "awesome_print"

require_relative "./bg_stat_export_json_reader"
require_relative "./insert_sql_destination"
require_relative "./remap_column_name"

module BGstatGameBackupImporter
  module_function

  BACKUP_COLUMNS_DEFINITION = {
    id: :id,
    bggId: :bgg_id,
    uuid:  :bg_stat_uuid,
    name: :name
  }

  def etl(backup_file:, database:)
    pastel = Pastel.new
    initial_db_games_count = 0
    Kiba.parse do
      extend Kiba::Common::DSLExtensions::ShowMe

      pre_process do
        database.create_table? :games do
          primary_key :id
          String :name
          String :bgg_id
          String :bg_stat_uuid
        end
        initial_db_games_count = database[:games].count
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

      transform RemapColumnName,
        column_row_mapping: BACKUP_COLUMNS_DEFINITION

      destination InsertSQLDestination,
        database: database,
        table_name: "games",
        on_error: ->(error, row) {
          puts pastel.red("Error inserting #{row}")
          puts error.inspect
        }

      post_process do
        imported_games_count = database[:games].count - initial_db_games_count
        if imported_games_count > 0
          puts pastel.green("✓ Imported #{imported_games_count} games")
        else
          puts "No games imported database already up to date"
        end
      end
    end
  end
end
