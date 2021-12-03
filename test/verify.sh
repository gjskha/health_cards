cat <<EOF >"/tmp/data.json"
{
  "resourceType": "Parameters",
  "parameter": [{
    "name": "credentialType",
    "valueUri": "https://smarthealth.cards#covid19"
  }]
}
EOF

curl -X POST 'https://healthcards.herokuapp.com/Patient/8/$health-cards-issue' \
-H 'Content-Type: application/fhir+json' -H 'Accept: application/fhir+json' \
-d @/tmp/data.json

cp /tmp/data.json /tmp/data.txt

curl -X POST 'https://healthcards.herokuapp.com/Patient/8/$health-cards-issue' \
-H 'Content-Type: application/fhir+json' -H 'Accept: application/fhir+json' \
-d /tmp/data.txt


