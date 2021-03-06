module Jsonapi
  module Matchers
    class AttributesIncluded
      include Jsonapi::Matchers::Shared

      attr_reader :description

      def initialize(attribute_name, location, description)
        @attribute_name = attribute_name
        @location = location
        @failure_message = nil
        @failure_message_when_negated = nil
        @description = description
      end

      def with_value(expected_value)
        @check_value = true
        @expected_value = expected_value
        self
      end

      def with_record(expected_record)
        @check_record = true
        @expected_record_id = expected_record.id.to_s
        self
      end

      def matches?(target)
        @target = normalize_target(target)
        return false unless @target

        if @location
          @target = @target.try(:[], :data).try(:[], @location)
        else
          @target = @target.try(:[], :data)
        end

        @value = @target.try(:[], @attribute_name)

        if @check_value
          value_exists?
        elsif @check_record
          record_exists?
        else
          @target.key?(@attribute_name)
        end
      end

      def failure_message
        @failure_message || "expected attribute '#{@attribute_name}' to be included in #{@target.as_json.ai}"
      end

      def failure_message_when_negated
        @failure_message_when_negated || "expected attribute '#{@attribute_name}' not to be included in #{@target.as_json.ai}"
      end

      private

      def value_exists?
        if @expected_value.to_s == @value.to_s
          @failure_message_when_negated = "expected key '#{@attribute_name}' to not be '#{@expected_value}', but it was '#{@value}'"
          true
        else
          @failure_message = "expected '#{@expected_value}' for key '#{@attribute_name}', but got '#{@value}'"
          false
        end
      end

      def record_exists?
        data = @value.try(:[], 'data')

        if data.is_a?(Array)
          if data.map{|d| d['id']}.include?(@expected_record_id)
            @failure_message_when_negated = "expected '#{@attribute_name}' not to contain the id '#{@expected_record_id}', but got '#{@value['data']}'"
            return true
          else
            @failure_message = "expected '#{@expected_record_id}' to be an id in relationship '#{@attribute_name}', but got '#{@value['data']}'"
            return false
          end
        elsif @expected_record_id == @value.try(:[], 'data').try(:[], 'id')
          @failure_message_when_negated = "expected '#{@expected_record_id}' not to be the id for relationship '#{@attribute_name}', but got '#{@value}'"
          return true
        else
          @failure_message = "expected '#{@expected_record_id}' to be the id for relationship '#{@attribute_name}', but got '#{@value}'"
          return false
        end
      end
    end

    module Attributes
      def have_id(id)
        AttributesIncluded.new('id', nil, "have id: #{id}").with_value(id)
      end

      def have_type(type)
        AttributesIncluded.new('type', nil, "have type: #{type}").with_value(type)
      end

      def have_attribute(attribute_name)
        AttributesIncluded.new(attribute_name, :attributes, "have attribute: #{attribute_name}")
      end

      def have_relationship(relationship_name)
        AttributesIncluded.new(relationship_name, :relationships, "have relationship: #{relationship_name}")
      end
    end
  end
end
