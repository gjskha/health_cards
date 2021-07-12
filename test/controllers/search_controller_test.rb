# frozen_string_literal: true

require 'test_helper'

class SearchControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Mock QBP client responses
    @qbp_application_error = { qbp_response: { code: :AE } }
    @qbp_application_rejected = { qbp_response: { code: :AR } }
    @qbp_not_found = { qbp_response: { code: :NF } }
    @qbp_ok = { qbp_response: {
      code: :OK,
      patient: File.read(Rails.root.join('test', 'fixtures', 'files', 'covid-bundle.json'))
    } }
    @qbp_protected_data = { qbp_response: { code: :PD } }
    @qbp_too_much = { qbp_response: { code: :TM } }
    @qbp_bad_code = { qbp_response: { code: :bad } }

    # The variables below need to be updated to match IIS sandbox
    @good_query_params = { patient: { given: 'BethesdaAIRA',
                                      family: 'WeilAIRA',
                                      birth_date: '06/10/2017' } }

    @vague_query_params = { patient: { family: 'WeilAIRA',
                                       birth_date: '06/10/2017' } }

    @negative_query_parans = { patient: { given: 'Not',
                                          second: 'In',
                                          family: 'IIS',
                                          birth_date: '02/31/2000' } }
  end

  test 'should get search form' do
    get search_form_url
    assert_response :success
  end

  test 'should get search form with demo data' do
    get search_form_url, params: { 'autofill' => 'yes' }
    assert_response :success

    assert_select 'form' do
      assert_select 'input#patient_given' do |elements|
        elements.each { |element| assert_match(/\svalue="[^"]+"\s/, element.to_s) }
      end
      assert_select 'input#patient_family' do |elements|
        elements.each { |element| assert_match(/\svalue="[^"]+"\s/, element.to_s) }
      end
      assert_select 'input#patient_birth_date' do |elements|
        elements.each { |element| assert_match(/\svalue="[^"]+"\s/, element.to_s) }
      end
    end
  end

  test 'good query should redirect to found patient' do
    assert_raises(NotImplementedError) { post(search_query_url, { params: @good_query_params }) }
    # assert_redirected_to @patient1
  end

  test 'vague query params should redirect to search form' do
    assert_raises(NotImplementedError) { post(search_query_url, { params: @vague_query_params }) }
    # assert_redirected_to search_form_url
  end

  test 'negative query params should return no data page' do
    assert_raises(NotImplementedError) { post(search_query_url, { params: @negative_query_params }) }
    # assert_response :success
    # assert @response.body
    # assert_not_empty @response.body
  end

  test 'QBP client application error response should redirect to form' do
    post(search_query_url, { params: @qbp_application_error })
    assert_redirected_to search_form_url
  end

  test 'QBP client application rejected response should return bad request with rejected page' do
    post(search_query_url, { params: @qbp_application_rejected })
    assert_response :bad_request
    assert_not_empty @response.body
  end

  test 'QBP client not found response should return no data page' do
    post(search_query_url, { params: @qbp_not_found })
    assert_response :success
    assert_not_empty @response.body
  end

  test 'QBP client ok response should redirect to patient' do
    post(search_query_url, { params: @qbp_ok })

    bundle = FHIR.from_contents(@qbp_ok[:patient])
    bundle.entry.each do |entry|
      if rentry.resource.resourceType.upcase == 'PATIENT'
        patient_json = entry.resource.to_json
        break
      end
    end

    assert_redirected_to Patient.find_by!(json: FHIR.from_contents(patient_json))
  end

  test 'QBP client protected data response should return forbidden with protected page' do
    post(search_query_url, { params: @qbp_protected_data })
    assert_response :forbidden
    assert_not_empty @response.body
  end

  test 'QBP client too much response should redirect to form' do
    post(search_query_url, { params: @qbp_too_much })
    assert_redirected_to search_form_url
  end

  test 'QBP client invalid response code raises error' do
    assert_raises(StandardError) { post(search_query_url, params: @qbp_bad_code) }
  end
end
