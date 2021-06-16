require "savon"
require "ruby-hl7"
require 'faraday'
require 'qpd'

module HealthCards
  module QBPClient
    def query()
        service_def = "../assets/service.wsdl"
        puts "WSDL #{service_def}"
        
        client = Savon.client(wsdl: service_def, 
            endpoint: "http://localhost:8081/iis-sandbox/soap", 
            pretty_print_xml: true)
        puts client.operations
        
        response = client.call(:connectivity_test) do
            message echoBack: "?"
        end
        
        puts response
        
        raw_input = open( "../assets/qbp.hl7" ).readlines
        msg_input = HL7::Message.new( raw_input )
        uid = rand(10000000000).to_s
        
        msh = msg_input[:MSH]
        msh.time = Time.now
        msh.message_control_id = uid
        qpd = msg_input[:QPD]
        
        qpd.query_tag = uid
        
        patient_id_list = HL7::MessageParser.split_by_delimiter(qpd.patient_id_list, msg_input.item_delim)
        patient_id_list[1] = 'J19X5' # ID
        patient_id_list[4] = 'AIRA-TEST' # assigning authority
        patient_id_list[5] = 'MR' # identifier type code
        qpd.patient_id_list = patient_id_list.join(msg_input.item_delim)
        
        patient_name = HL7::MessageParser.split_by_delimiter(qpd.patient_name, msg_input.item_delim)
        patient_name[0] = 'WeilAIRA' # family name
        patient_name[1] = 'BethesdaAIRA' # given name
        patient_name[2] = 'Delvene' # second name
        patient_name[3] = '' # suffix name
        qpd.patient_name = patient_name.join(msg_input.item_delim)
        
        mother_maiden_name = HL7::MessageParser.split_by_delimiter(qpd.mother_maiden_name, msg_input.item_delim)
        mother_maiden_name[0] = 'WeilAIRA' # family name
        mother_maiden_name[1] = 'BethesdaAIRA' # given name
        mother_maiden_name[6] = 'M' # name type code, M = Maiden Name
        qpd.mother_maiden_name = mother_maiden_name.join(msg_input.item_delim)
        
        qpd.patient_dob = "20170610"
        
        qpd.admin_sex = "F"
        
        address = HL7::MessageParser.split_by_delimiter(qpd.address, msg_input.item_delim)
        address[0] = '1113 Wollands Kroon Ave' # street address
        address[2] = 'Hamburg' # city
        address[3] = 'MI' # state
        address[4] = '48139' # zip
        address[6] = 'P' # address type
        qpd.address = address.join(msg_input.item_delim)
        
        phone_home = HL7::MessageParser.split_by_delimiter(qpd.phone_home, msg_input.item_delim)
        phone_home[5] = '810' # area code
        phone_home[6] = '2499010' # local number
        qpd.phone_home = phone_home.join(msg_input.item_delim)
        
        puts "request:"
        puts msg_input.to_hl7
        
        response = client.call(:submit_single_message) do
            message username: "mitre", password: "mitre", facilityID: "MITRE Healthcare", hl7Message: msg_input
        end
        
        msg_output = HL7::Message.new(response.body[:submit_single_message_response][:return])
        puts "response:"
        puts msg_output.to_hl7
        
        fhir_response = Faraday.post('http://localhost:3000/api/v0.1.0/convert/text',
            msg_output.to_hl7,
            "Content-Type" => "text/plain")
        puts "fhir:"
        puts fhir_response.body

        return fhir_response.body
    end
  end
end