module Classification
  class GlobalParam < PuppetParam
    def enc
      return {} unless puppet_facet
      
      values = values_hash

      parameters = {}
      class_parameters.each do |key|
        parameters[key.to_s] = value_of_key(key, values)
      end
      parameters
    end

    protected

    def class_parameters
      @keys ||= VariableLookupKey.global_parameters_for_class(puppetclass_ids)
    end
  end
end
