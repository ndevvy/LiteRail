require_relative 'searchable'
require 'active_support/inflector'
require 'byebug'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )
  def model_class
    @class_name.to_s.constantize
  end
  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] || "#{name}".foreign_key.to_sym
    @class_name = options[:class_name] || "#{name}".camelize
    @primary_key = options[:primary_key] || :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key] || self_class_name.to_s.foreign_key.to_sym
    @class_name = options[:class_name] || "#{name}".singularize.camelize
    @primary_key = options[:primary_key] || :id
  end
end

module Associatable
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    define_method(name) do
      options.model_class.where({options.primary_key => self.send(options.foreign_key)}).first
    end
    assoc_options[name] = options
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)

    define_method(name) do
      options.model_class.where( { options.foreign_key => self.send(options.primary_key)})
    end

  end

  def has_one_through(name, through_name, source_name)

    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      source_table = source_options.table_name
      through_table = through_options.table_name

      source_primary_key = source_options.primary_key
      through_primary_key = through_options.primary_key

      key = self.send(through_options.foreign_key)
      results = DBConnection.execute2(<<-SQL, key)
        SELECT
          #{source_table}.*
        FROM
          #{through_table}
        JOIN
          #{source_table} ON #{through_table}.#{source_primary_key} = #{source_table}.#{source_primary_key}
        WHERE
          #{through_table}.#{through_primary_key} = ?
        SQL
        source_options.model_class.parse_all(results).last
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end
