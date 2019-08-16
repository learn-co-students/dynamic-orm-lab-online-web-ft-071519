require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord
  def self.table_name
    # take the name of the class (self) and convert it to a downcased, pluralized string
    self.to_s.downcase.pluralize
  end

  def self.column_names

    # SQL query returns an array of hashes that describes the actual table.
    sql = "PRAGMA table_info('#{table_name}')"

    # Each hash in above array = 1 column in table
    table_info = DB[:conn].execute(sql)
    column_names = []

    # Iterate over table array to access the columns.
    table_info.each do |row|
      # Shovel the column name value into column_names array.
      column_names << row["name"]
    end

    # Use .compact to remove any nil values
    column_names.compact
  end


  # Initialize takes in a hash of options.
  # Make sure your attr_accessors are defined in your child class
  def initialize(options={})
    # Iterate over options hash
    options.each do |property, value|
      # Set student with attributes
      self.send("#{property}=", value)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if { |col| col == "id" }.join(", ")
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
      VALUES (#{values_for_insert})"

    DB[:conn].execute(sql)

    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
    DB[:conn].execute(sql, name)
  end

  def self.find_by(attribute_hash)
    value = "'#{attribute_hash.values[0]}'"

    sql = "SELECT * FROM #{self.table_name} WHERE #{attribute_hash.keys[0]} = #{value}"
    DB[:conn].execute(sql)

  end
end