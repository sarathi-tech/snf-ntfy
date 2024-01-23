CREATE OR REPLACE NETWORK RULE ntfy_api_network_rule
 MODE = EGRESS
 TYPE = HOST_PORT
 VALUE_LIST = ('10.0.0.4:8000'); -- use your public exposed IP for the API

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION ntfy_api_access_integration
 ALLOWED_NETWORK_RULES = (ntfy_api_network_rule)
 ENABLED = true;

CREATE OR REPLACE FUNCTION Ntfy_Push_Notification(Message varchar)
 RETURNS STRING
 LANGUAGE PYTHON
 RUNTIME_VERSION = 3.8
 HANDLER = 'ntfy_push'
 EXTERNAL_ACCESS_INTEGRATIONS = (ntfy_api_access_integration)
 PACKAGES = ('snowflake-snowpark-python','requests')
 AS
 $$
 import snowflake
 import requests
 import json
 
 def ntfy_push():
 base_url = "http://10.0.0.4:8000/ntfyrun?message="
 full_url = base_url + MESSAGE 
 r = requests.get(full_url)
 return r.json()
 $$;

SELECT Ntfy_Push_Notification("Message from Snowflake");