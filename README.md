## ActiveRecord Jr.
Rails's ActiveRecord provides us with a fleet of useful ORM (object-relational mapping) methods for setting up relations between Rails models and accessing the database accordingly.

In that vein, I wrote an **ActiveRecord Jr.** to create model-level methods for creating, updating, finding, and retrieving records, as well as manipulating associated records via _has many_, _belongs to_, and _has one through_ associations.

### SQLObject
- Similar to ActiveRecord's model methods, this class wraps SQL tables and defines methods for each of a table's columns. This is accomplished by saving the column data - or **attributes** - as instance variables on the `SQLObject`. Ruby's `Object#instance_variable_get` is very useful here.

````ruby
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
````

````ruby
def attributes
  attributes = self.instance_variable_get("@attributes")
  attributes ||= self.instance_variable_set("@attributes", {})
  attributes
end
````
- **SQLObject#all**: returns all records in a table
- **SQLObject#find**: finds a record by id (e.g., `Cat.find(3)`) returns an `SQLObject` wrapping the row in the `cats` table with id 3)

````ruby
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
````

### Searchable
The `Searchable` module's `#where` method implements easy database searching with the following syntax: `Cat.where({owner: 1})`.  Taking a hash of params, it builds out the appropriate SQL query and returns the results, wrapped in a `SQLObject`.

### Associations
**Now for the good stuff!** Methods supporting associations for the `SQLObject` class are meta-programmed by first wrapping the options (such as :foreign_key, :class_name, and :primary_key) in a specialized `AssocOptions` sub-class. The options object stores the options as instance variables and provides helper methods for generating the model class and table name.  

````ruby
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
````

**Methods** for easy SQL querying are then generated using `Object#define_method`.

````ruby
def belongs_to(name, options = {})
  options = BelongsToOptions.new(name, options)
  define_method(name) do
    options.model_class.where({options.primary_key => self.send(options.foreign_key)}).first
  end
  assoc_options[name] = options
end
````
