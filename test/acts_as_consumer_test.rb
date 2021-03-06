require File.expand_path('test_helper', File.dirname(__FILE__))

Dictionary.acts_as_dictionary

class TestConsumer < TestSupporter
end

class TestConsumeOneColumn < TestConsumer
  Student.acts_as_dict_consumer on: :city

  def test_student_should_has_method_city
    assert Student.new.respond_to?(:city), 'student should has method city'
    assert Student.new.respond_to?(:create_city), 'student should has method create_city'
    assert_includes RailsDictionary.config.defined_sti_klass, 'Dictionary::City'
  end

  def test_dictionary_city_class_exist
    assert Dictionary.const_defined?('City'), 'Dictionary::City should be defined'
    assert_includes RailsDictionary.config.defined_sti_klass, 'Dictionary::City'
  end
end

class TestConsumeMultipleColumns < TestConsumer
  Student.acts_as_dict_consumer on: [:city, :school]

  def test_student_should_has_method_city
    assert Student.new.respond_to?(:city), 'student should has method city'
    assert Student.new.respond_to?(:create_city), 'student should has method create_city'
    assert Student.new.respond_to?(:school), 'student should has method city'
    assert Student.new.respond_to?(:create_school), 'student should has method city'
  end

  def test_dictionary_city_and_school_exist
    assert Dictionary.const_defined?('City'), 'Dictionary::City should be defined'
    assert Dictionary.const_defined?('School'), 'Dictionary::City should be defined'
    assert_equal(['Dictionary::City', 'Dictionary::School'], RailsDictionary.config.defined_sti_klass)
  end
end
