module RailsDictionary
  module ActsAsDictConsumer
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      # Generate dynamic instance method named_column to consumer model
      # def named_city(locale=nil)
      #
      # end
      #
      def named_dict_value_for_many_to_many
        relation_name = @dict_relation_name
        relation_type = @dict_relation_type
        class_opt = @opt
        method_name="named_#{relation_name}"
        define_method(method_name) do
          class_opt[:class_name].constantize.where(id: send(relation_name)).pluck(:name)
        end
      end

      # Build dynamic method column_name= to the consumer model
      #
      # ex:
      #   def city_name=(value, options = {})
      #     send "city=", dictionary_obj
      #   end
      def dict_name_equal
        relation_name = @dict_relation_name
        relation_type = @dict_relation_type
        method_name = "#{relation_name}_name="
        class_opt = @opt

        define_method(method_name) do |value, options={}|
          dicts = class_opt[:class_name].constantize.where(name: Array(value), type: class_opt[:class_name])
          if dicts
            if relation_type == :belongs_to
              send "#{relation_name}=", dicts.first
            elsif relation_type == :many_to_many
              send "#{relation_name}=", dicts.map(&:id)
            else
              raise "Wrong relation method name: #{relation_type}"
            end
          else
            # do nothing ?
          end
        end
      end

      # dont think instance var is a good sollution
      # cause the consumer class will include other lib too
      def build_dict_relation(opt)
        @opt = opt
        @dict_relation_name = @opt.delete :on
        raise 'params on cant be nil' if @dict_relation_name.nil?
        @dict_relation_type = @opt.delete(:relation_type) || :belongs_to
        # @opt[:foreign_key] ||= "#{@dict_relation_name}_id"
        @opt[:class_name] ||= "#{RailsDictionary.config.dictionary_klass}::#{@dict_relation_name.to_s.singularize.camelize}"
        begin
          @opt[:class_name].constantize
        rescue NameError
          ::RailsDictionary.init_dict_sti_class(@opt[:class_name])
        end
        if @dict_relation_type.to_sym == :belongs_to
          send @dict_relation_type, @dict_relation_name, @opt
        elsif @dict_relation_type.to_sym == :many_to_many
          named_dict_value_for_many_to_many

          inverse_relation_for_many_to_many if respond_to? "#{@dict_relation_name}_contain".to_sym
        end
        dict_name_equal
      end

      # Not Tested
      def inverse_relation_for_many_to_many
        inverse_of_name = @opt[:inverse_of] || name.downcase.pluralize
        dict_relation_name = @dict_relation_name
        current_class = self

        @opt[:class_name].constantize.send :define_method, inverse_of_name.to_sym do
          current_class.send("#{dict_relation_name}_contain", id)
        end
      end

    end # END ClassMethods

  end
end
