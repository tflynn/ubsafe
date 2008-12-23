module Kernel

  # With thanks to the Mack framework
  
  ##
  # Aliases a class method to a new name. It will only do the aliasing once, to prevent
  # issues with reloading a class and causing a StackLevel too deep error.
  # The method takes two arguments, the first is the original name of the method, the second,
  # optional, parameter is the new name of the method. If you don't specify a new method name
  # it will be generated with _original_<original_name>.
  # 
  # Example:
  #   class President
  #     alias_class_method :good
  #     alias_class_method :bad, :old_bad
  #     def self.good
  #       'Bill ' + _original_good
  #     end
  #     def self.bad
  #       "Either #{old_bad}"
  #     end
  #   end
  #
  # @param orig_name [String] The original class method to alias
  # @param new_name [String] The new alias. Defaults to '_ubsafe_original_[name]'
  #
  def alias_class_method(orig_name, new_name = "_ubsafe_original_#{orig_name}")
    eval(%{
      class << self
        alias_method :#{new_name}, :#{orig_name} unless method_defined?("#{new_name}")
      end
    })
  end
  
end
