# frozen_string_literal: true

class SearchController < ApplicationController
  # GET /search/form
  def form
    @patient = Patient.new(search_params)
  end

  # POST /search/query
  def query
    results = qbp_query(search_params)

    case results[:code]
    when :AE # Application Error
      logger.error 'QBP client returned Application Error'
      redirect_to search_form_url, alert: 'Sorry there was an error, please try again. If problem persists contact system administrator.'
    when :AR  # Application Rejected
      logger.error 'QBP client returned Application Rejected'
      render 'rejected.html.erb'
    when :NF  # No Data Found
      render 'no_data.html.erb'
    when :OK  # Data Found (No Errors)
      json_bundle = translate(results[:patient])
      if validate(json_bundle) && create_patient(json_bundle)
        redirect_to @patient
      else
        logger.error "Failed to validate patient from FHIR translation of QBP response"
        redirect_to search_form_url, alert: 'Information from IIS could not be validated.'
      end
    when :PD  # Protected Data
      render 'protected.html.erb'
    when :TM  # Too Much Data Found
      redirect_to search_form_url, alert: 'Too many matches found, please enter more information.'
      # is there a case where one patient is found, but there are too many immunizations to load?
    else
      raise StandardError, "QBP client code #{results[:code]} not recognized"
    end
  end

  private

  def search_params
    if params[:action] == 'form'
      params[:autofill] ? helpers.real_patient_params[:patient] : {}
    else
      patient_params = params.require(:patient).permit([:given, :family, :second, :suffix,
                                                        :birth_date, :gender, :phone,
                                                        :list_id, :assigning_authority, :identifier_type_code,
                                                        :mother_maiden_given_name, :mother_maiden_family_name,
                                                        :street_line1, :street_line2, :city, :state, :zip_code]).to_hash.transform_keys! { |k| k.to_sym }
      patient_params.transform_values! { |v| v.strip }
      patient_params.transform_values! { |v| v.empty? ? nil : v }
      build_query_params(patient_params)
    end
  end

  def build_query_params(patient_params)
    query_params = {
      patient_name: patient_params.slice(:given, :family, :second, :suffix),
      patient_dob: patient_params[:birth_date].split('/').reverse.join(''),
      patient_list: patient_params.slice(:assigning_authority,
                                         :identifier_type_code).merge!({ id: patient_params[:list_id] }),
      mother_maiden_name: { family: patient_params[:mother_maiden_family_name],
                            given: patient_params[:mother_maiden_given_name] },
      sex: patient_params[:gender],
      address: patient_params.slice(:city, :state).merge!({ zip: patient_params[:zip_code] })
    }

    if patient_params[:street_line2]
      query_params[:address][:street] = patient_params[:street_line1] + ', ' + patient_params[:street_line2]
    elsif patient_params[:street_line1]
      query_params[:address][:street] = patient_params[:street_line1]
    end

    if patient_params[:phone]
      query_params[:phone] =
        { area_code: patient_params[:phone].split('-')[0],
          local_number: patient_params[:phone].split('-')[1..3].join('') }
    end

    # omitting: :address => { :address_type }
    # omitting: :multiple_birth_indicator, :birth_order, :client_last_updated_date, :client_last_update_facility
    query_params
  end

  def create_patient(json)
    bundle = FHIR.from_contents(json)
    @patient = Patient.new({json: nil})

    bundle.entry.each do |entry|
      case entry.resource.resourceType.upcase
      when "PATIENT"
        @patient.json = entry.resource.to_json
      when "IMMUNIZATION"
        @patient.immunizations.build({json: entry.resource.to_json})
      else
        logger.warn "Unexpected resource #{entry.resource.resourceType} found in bundle from QBP client"
      end
    end

    @patient.save
  end

  def qbp_query(query_hash)
    raise NotImplementedError, "Calling QBP Client w/ parameter: #{query_hash}"
  end

  def translate(hl7v2_text)
    raise NotImplementedError, "Calling QBP Client w/ parameter: #{hl7v2_text}"
  end

  def validate(fhir_json)
    raise NotImplementedError, "Calling validation on QBP response w/ parameter #{fhir_json}"
  end
end
