require "kiba"
require "kiba-common/dsl_extensions/show_me"
require "awesome_print"

require_relative "./bg_stat_export_json_reader"
require_relative "./insert_sql_destination"
require_relative "./remap_column_name"

module BGstatPlayBackupImporter
  module_function

  BACKUP_COLUMNS_DEFINITION = {
    uuid:  :bg_stat_uuid,
    gameRefId: :game_id,
    playDate: :played_at
  }

  def etl(backup_file:, database:)
    pastel = Pastel.new
    initial_db_plays_count = 0
    Kiba.parse do
      extend Kiba::Common::DSLExtensions::ShowMe

      pre_process do
        database.create_table! :plays do
          primary_key :id
          foreign_key :game_id, :games, null: false
          column :played_at, Date
          column :bg_stat_uuid, String
          index :game_id
        end
        initial_db_plays_count = database[:plays].count
      end

      source BGStatExportJsonReader, file: backup_file, section: "plays"

      transform do |row|
        if row["metaData"]
          row["metaData"] = Oj.load(row["metaData"], symbol_key: true)
        end
        row
      end

      show_me!

      transform RemapColumnName,
        column_row_mapping: BACKUP_COLUMNS_DEFINITION


      transform do |row|
        row[:played_at] = Date.strptime(row[:played_at], "%Y-%m-%d")
        row
      end


      destination InsertSQLDestination,
        database: database,
        table_name: "plays",
        on_error: ->(error, row) {
          puts pastel.red("Error inserting #{row}")
          puts error.inspect
        }

      post_process do
        imported_plays_count = database[:plays].count - initial_db_plays_count
        if imported_plays_count > 0
          puts pastel.green("✓ Imported #{imported_plays_count} games")
        else
          puts "No plays imported database already up to date"
        end
      end
    end
  end
end
