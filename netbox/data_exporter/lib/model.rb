module Model
  module ClassMethod
    def attribute_names
      @attribute_names ||= []
    end

    def attribute(method_name)
      attribute_names << method_name
    end
  end

  def self.included(klass)
    klass.extend(ClassMethod)
  end

  def to_h
    self.class.attribute_names.map do |k|
      [k.to_s, __send__(k)]
    end.to_h
  end
end

