require "sequel"

class InsertSQLDestination
  attr_reader :database, :table_name, :on_error

  def initialize(database:, table_name:, on_error: -> {})
    @database = database
    @table_name = table_name
    @on_error = on_error
  end

  def write(row)
    database[table_name.to_sym]
      .insert_conflict
      .insert(
        id: row["id"],
        bgg_id: row["bggId"],
        name: row["name"],
        bg_stat_uuid: row["uuid"]
      )
  rescue Sequel::DatabaseError => e
    on_error.call(e, row)
  end
end
