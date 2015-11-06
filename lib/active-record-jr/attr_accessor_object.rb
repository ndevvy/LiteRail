class AttrAccessorObject
  def self.my_attr_accessor(*names)
    names.each do |variable|
      define_method("#{variable}") do
        instance_variable_get("@#{variable.to_s}")
        end

      define_method("#{variable}=") do |new_var|
        instance_variable_set("@#{variable.to_s}", new_var.to_s)
      end

    end
  end
end
