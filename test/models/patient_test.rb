# frozen_string_literal: true

require 'test_helper'
require 'serializers/fhir_serializer'

class PatientTest < ActiveSupport::TestCase
  test 'json serialization' do
    p1 = Patient.create(given: 'Foo', family: 'Bar', gender: 'male',
                        birth_date: Time.zone.today)
    assert p1.valid?, p1.errors.full_messages.join(', ')
    p2 = Patient.find(p1.id)
    assert_equal p1.given, p2.given
    assert_equal p1.family, p2.family
    assert_equal p1.gender, p2.gender
    assert_equal p1.birth_date, p2.birth_date
  end

  test 'invalid json validation' do
    assert_raises(ActiveRecord::SerializationTypeMismatch) do
      Patient.create(json: "asdfasdasdf'jkl")
    end
  end

  test 'invalid fhir json' do
    patient = Patient.create(json: FHIR::Patient.new(gender: 'INVALID GENDER'))
    assert patient.new_record?
  end

  test 'health card creation from patient and immunization json' do
    patient = Patient.create(given: 'foo', birth_date: Time.zone.today)
    vax = Vaccine.create(code: 'a')
    patient.immunizations.create(vaccine: vax, occurrence: Time.zone.today)

    assert_not_nil patient.json.id
    assert_not_nil patient.immunizations.first.id

    bundle = patient.to_bundle(rails_issuer.url)

    assert bundle.valid?

    hc = rails_issuer.create_health_card(bundle)

    assert_nothing_raised do
      new_bundle = hc.strip_fhir_bundle

      assert_entry_references_match(new_bundle.entry[0], new_bundle.entry[1].resource.patient)
    end
  end

  test 'test blank date' do
    patient = Patient.create(given: 'foo', birth_date: '')
    assert patient.birth_date.nil?
    assert patient.json.birthDate.nil?
  end

  test 'update patient' do
    patient = Patient.create
    given = 'foo'
    assert patient.update(given: given)
    patient.reload
    assert_equal given, patient.given
  end

  test 'valid patient match' do
    birthday = Time.zone.today
    patient = Patient.create(given: 'Foo', family: 'Bar', birth_date: birthday)
    assert patient.match?({ given: 'Foo', family: 'Bar', birth_date: birthday })
  end

  test 'valid patient match with minimal parameters' do
    patient = Patient.create(given: 'Goo', family: 'Bar', birth_date: Time.zone.today)
    assert patient.match?({ given: 'Goo' })
  end

  test 'invalid patient match' do
    patient = Patient.create(given: 'Hoo', family: 'Bar', birth_date: Time.zone.today)
    assert_not patient.match?({ given: 'Does', family: 'Not Exist', birth_date: Time.zone.tomorrow })
  end

  test 'patient select' do
    3.times do |i|
      Patient.create(given: i.to_s, family: 'Nar', birth_date: Time.zone.yesterday)
    end
    selection = Patient.select { |p| p.match?({ family: 'Nar' }) }
    assert_not_nil selection
    assert_equal 3, selection.length
    selection.each { |p| assert_equal 'Nar', p.family }
  end

  test 'create patient from fhir bundle' do
    assert_difference ['Patient.count', 'Immunization.count'] do
      json = File.read(Rails.root.join('test', 'fixtures', 'files', 'covid-bundle.json'))
      patient = Patient.create_from_bundle!(json)
      assert_not_nil patient
    end
  end
end
