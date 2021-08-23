# frozen_string_literal: true

require 'health_cards/attribute_filters'
require 'health_cards/card_types'

module HealthCards
  # Implements HealthCard for use with COVID Vaccination IG
  class COVIDHealthCard < HealthCards::HealthCard
    fhir_version '4.0.1'

    additional_types 'https://smarthealth.cards#covid19'
    additional_types 'https://smarthealth.cards#immunization'
    additional_types 'https://smarthealth.cards#laboratory'

    allow type: FHIR::Patient, attributes: %w[name birthDate]
    allow type: FHIR::Immunization, attributes: %w[status vaccineCode patient occurrenceDateTime lotNumber]
    allow type: FHIR::Observation, attributes: %w[status code valueCodeableConcept patient effectiveDateTime]
  end
end
