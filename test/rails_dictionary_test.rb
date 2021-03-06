require File.expand_path('test_helper', File.dirname(__FILE__))

Dictionary.acts_as_dictionary
class TestRailsDictionary < TestSupporter

  class TestActiveRecordExtension < TestRailsDictionary
    [:acts_as_dictionary, :acts_as_dict_consumer].each do |method_name|
      define_method "test_#{method_name}_exists_ar" do
        assert_includes ActiveRecord::Base.methods, method_name
      end
    end
  end

  class PreTestDatabase < TestRailsDictionary

    def test_no_dictionary_data_exist_before
      assert_equal 0, Dictionary.count, 'dicionaries table should be blank'
    end
  end

  class TestInitSubDictClass < TestRailsDictionary
    def setup
      super
      if Dictionary.const_defined? 'City'
        Dictionary.send :remove_const, 'City'
        RailsDictionary.config.defined_sti_klass.delete('Dictionary::City')
      end
      if Object.const_defined? 'School'
        Object.send :remove_const, 'School'
        RailsDictionary.config.defined_sti_klass.delete('School')
      end
    end

    def test_school_sub_class
      @shanghai = Dictionary.create!(name: "wuhan first medium school", type: 'School')
      assert_equal Dictionary, School.superclass
      assert_includes RailsDictionary.config.defined_sti_klass, 'School'
    end

    def test_dictionary_city_class_when_create_dictionary
      @shanghai = Dictionary.create!(name: "shanghai", type: 'Dictionary::City')
      assert_equal Dictionary, Dictionary::City.superclass
    end

    def test_dictionary_city_class_when_assign_type
      beijing = Dictionary.new(name: 'beijing')
      beijing.type = 'Dictionary::City'
      beijing.save!
      assert Dictionary, Dictionary::City.superclass
    end

    def test_dictionary_city_class_when_assign_type_in_new
      beijing = Dictionary.new(name: 'beijing', type: 'Dictionary::City')
      beijing.save!
      assert Dictionary, Dictionary::City.superclass
    end

    def test_data_insert_before_type_class_init
      Dictionary.find_by_sql("insert into Dictionaries (name, type) values ('wuhan', 'Dictionary::City')")
      assert_equal 1, Dictionary.count
      assert_equal 'wuhan', Dictionary.last.name
    end
  end
end

class TestWithDB < TestRailsDictionary
  def setup
    super
    Dictionary.acts_as_dictionary
    @beijing, @shanghai = prepare_city_data

    @stu_beijing = Student.create! email: "beijing@dict.com", city_id: @shanghai.id
    @stu_shanghai = Student.create! email: "shanghai@dict.com", city_id: @shanghai.id
  end
end

class TestStudent < TestWithDB
  def setup
    super
    Student.acts_as_dict_consumer on: [:city]
  end

  def test_city_name_equal_to_exist_dictionary_name
    assert_equal 1, Dictionary.where(name: "beijing").count
    @stu_shanghai.update_attributes city_name: "beijing"
    assert_equal 'beijing', @stu_shanghai.reload.city.name
    assert_equal 1, Dictionary.where(name: "beijing").count
  end

  def create_a_student_with_shanghai_city
    s = Student.create(city_name: "shanghai")
    s.reload
    s.city.name.should == "shanghai"
    assert_equal Dictionary.find_by(name: 'shanghai').id, s.city_id
    assert_equal 1, Dictionary.where(name: "shanghai").count
  end
end
