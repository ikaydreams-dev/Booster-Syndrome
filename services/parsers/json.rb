require 'json'

module Parsers
  class JSONParser
    def self.parse(json_string)
      JSON.parse(json_string)
    rescue JSON::ParserError => e
      { error: "Invalid JSON: #{e.message}" }
    end

    def self.stringify(obj, pretty: false)
      if pretty
        JSON.pretty_generate(obj)
      else
        JSON.generate(obj)
      end
    end

    def self.validate(json_string)
      JSON.parse(json_string)
      true
    rescue JSON::ParserError
      false
    end

    def self.deep_merge(hash1, hash2)
      hash1.merge(hash2) do |_key, old_val, new_val|
        if old_val.is_a?(Hash) && new_val.is_a?(Hash)
          deep_merge(old_val, new_val)
        else
          new_val
        end
      end
    end

    def self.flatten_keys(hash, prefix = '')
      result = {}
      hash.each do |key, value|
        new_key = prefix.empty? ? key.to_s : "#{prefix}.#{key}"
        if value.is_a?(Hash)
          result.merge!(flatten_keys(value, new_key))
        else
          result[new_key] = value
        end
      end
      result
    end

    def self.unflatten_keys(hash)
      result = {}
      hash.each do |key, value|
        parts = key.to_s.split('.')
        current = result
        parts[0...-1].each do |part|
          current[part] ||= {}
          current = current[part]
        end
        current[parts.last] = value
      end
      result
    end

    def self.get_nested(hash, path)
      keys = path.split('.')
      keys.reduce(hash) do |h, key|
        return nil unless h.is_a?(Hash)
        h[key] || h[key.to_sym]
      end
    end

    def self.set_nested(hash, path, value)
      keys = path.split('.')
      last_key = keys.pop
      current = hash

      keys.each do |key|
        current[key] ||= {}
        current = current[key]
      end

      current[last_key] = value
      hash
    end

    def self.remove_nested(hash, path)
      keys = path.split('.')
      last_key = keys.pop
      current = hash

      keys.each do |key|
        return hash unless current[key]
        current = current[key]
      end

      current.delete(last_key)
      hash
    end

    def self.deep_clone(obj)
      JSON.parse(JSON.generate(obj))
    end

    def self.compact(hash)
      hash.each_with_object({}) do |(k, v), result|
        next if v.nil?
        result[k] = v.is_a?(Hash) ? compact(v) : v
      end
    end
  end
end
