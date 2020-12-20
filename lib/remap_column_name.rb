class RemapColumnName
  attr_reader :column_row_mapping

  def initialize(column_row_mapping: {})
    @column_row_mapping = column_row_mapping
  end

  def process(row)
    column_row_mapping.inject({}) do |acc, (backup_key, sql_column)|
      acc[sql_column] = row[backup_key.to_s]
      acc
    end
  end
end
