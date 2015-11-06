require_relative 'db_connection'
require_relative 'sql_object'
require 'byebug'

module Searchable
  def where(params)
    # debugger
  where_line = params.keys.map { |k| "#{k} = ?" }.join(" AND ")
    table = DBConnection.execute2(<<-SQL, params.values.map { |value| value.to_s })
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_line}
      SQL
        results = []
        table.drop(1).each { |obj| results << self.new(obj) }
        results
  end
end
