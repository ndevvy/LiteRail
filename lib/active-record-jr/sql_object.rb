require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
require_relative 'searchable.rb'

class SQLObject
  extend Searchable
  extend Associatable
  def self.columns
    table = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
      LIMIT 1
      SQL
    table.first.map {|column| column.to_sym}
  end

  def self.finalize!
    columns = self.columns
    columns.each do |column|

      define_method(column) do
        attributes[column]
      end

      define_method("#{column}=") do |new_val|
        attributes[column] = new_val
      end

    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.tableize
    @table_name
  end

  def self.all
    all = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      SQL
      all = all.drop(1)
      parse_all(all)
  end

  def self.parse_all(results)
    objects = []
    results.each do |result|
      objects <<  self.new(result)
    end
    objects
  end

  def self.find(id)
    result = DBConnection.execute2(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
      SQL
      return if result.last.is_a?(Array)
      self.new(result.last)
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name)
      self.send("#{attr_name}=", value)
    end
  end

  def attributes
    attributes = self.instance_variable_get("@attributes")
    attributes ||= self.instance_variable_set("@attributes", {})
    attributes
  end

  def attribute_values
    columns = self.class.columns
    columns.map { |column| self.attributes[column] }
  end

  def insert
    col_names = self.class.columns.join(",")
    question_marks = []
    self.class.columns.length.times { question_marks << "?" }
    question_marks = question_marks.join(",")
    DBConnection.execute2(<<-SQL, *self.attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    columns = self.class.columns.map {|column| "#{column} = ?" }.join(", ")

    DBConnection.execute2(<<-SQL, *self.attribute_values)
      UPDATE
        #{self.class.table_name}
      SET
        #{columns}
      WHERE
        id = #{self.id}
    SQL
  end

  def save
    if self.id.nil?
      insert
    else
      update
    end
  end
end
