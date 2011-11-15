module Statusable
  def self.included(base)
    # add methods in ClassMethods into the meta class
    base.extend(ClassMethods)
  end
 
  module ClassMethods
    def has_statuses(statuses_hash)
      # allow for custom column name as 'status' is a very vague term
      if statuses_hash[:column_name].present?
        write_inheritable_attribute :column, statuses_hash[:column_name]
        
        # remove the option from the hash, the rest are assumed status'
        statuses_hash.delete(:column_name)
      else
        # default to status if not provided
        write_inheritable_attribute :column, "status"
      end
      
      class_inheritable_reader :column
      
      write_inheritable_attribute :statuses, statuses_hash
      class_inheritable_reader :statuses
 
      statuses_hash.each do |name, status|
        # Defines a query method on the model instance, one
        # for each status name (e.g. Song#published?)
        define_method("#{name}?") { self.read_attribute(column) == status }
        
        # add named_scope for the status
        named_scope name.to_sym, :conditions => {column => status}
 
        # Defines on the `statuses` object a method for
        # each status name. Each return the status value.
        # So you can do both statuses[:public] and statuses.public
        class<<statuses;self;end.send(:define_method, name) { status }
      end
 
      include InstanceMethods
    end
  end
 
  module InstanceMethods
    def status(format = nil)
      status = read_attribute(column)
      if format == :db
        status
      else
        statuses.invert[status]
      end
    end
 
    def status=(value)
      if statuses.has_key? value
        write_attribute column, statuses[value]
      elsif statuses.values.include? value
        write_attribute column, value
      else
        raise ActiveRecord::ActiveRecordError, "Invalid status #{value.inspect}"
      end
    end
 
  end
end