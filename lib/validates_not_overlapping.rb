module ValidatesNotOverlapping
  def validates_not_overlapping(start_attribute,finish_attribute, options = {})
    configuration = { 
        :message => "is conflicting with another.",
        :allow_equal_endpoints => false
      }
    configuration.update(options)
    
    send(validation_method(configuration[:on] || :save), options) do |record|
      # The check for an existing value should be run from a class that
      # isn't abstract. This means working down from the current class
      # (self), to the first non-abstract class. Since classes don't know
      # their subclasses, we have to build the hierarchy between self and
      # the record's class.
      class_hierarchy = [record.class]
      while class_hierarchy.first != self
        class_hierarchy.insert(0, class_hierarchy.first.superclass)
      end

      # Now we can work our way down the tree to the first non-abstract
      # class (which has a database table to query from).
      finder_class = class_hierarchy.detect { |klass| !klass.abstract_class? }
      
      condition_sql = <<-SQL
      ((start < :finish AND start >= :start) OR 
      (finish > :start AND finish <= :finish) OR 
      (start <= :start AND finish >= :finish) OR 
      (start > :start AND finish < :finish) OR
      (start <= :start AND finish IS NULL) OR
      (start <= :finish AND finish IS NULL) OR
      (:finish IS NULL AND finish is NULL)
      SQL
      
      condition_params = { :start => record.send(start_attribute), :finish => record.send(finish_attribute)}
      
      unless configuration[:allow_equal_endpoints]
        condition_sql << " OR (start = :finish) OR (finish = :start)"
      end
      
      condition_sql << ")"
      
      if scope = configuration[:scope]
        Array(scope).map do |scope_item|
          case scope_item
          when String
            condition_sql << " AND " + record.send(:interpolate_sql, scope_item)
          when Symbol
            scope_value = record.send(scope_item)
            condition_sql << " AND #{record.class.quoted_table_name}.#{scope_item} = :#{scope_item}"
            condition_params.update(scope_item => scope_value)
          end
        end
      end
      
      unless record.new_record?
        condition_sql << " AND #{record.class.quoted_table_name}.#{record.class.primary_key} <> :id"
        condition_params.update({:id => record.send(:id)})
      end
      
      results = finder_class.with_exclusive_scope do
        connection.select_all(
          construct_finder_sql(
            :select     => "#{start_attribute},#{finish_attribute}",
            :from       => "#{finder_class.quoted_table_name}",
            :conditions => [condition_sql, condition_params]
          )
        )
      end

      unless results.length.zero?
        found = true
        record.errors.add_to_base(configuration[:message]) if found
      end
    end
  end
end