
Snowflake offers a comprehensive alert and email notification system, enabling automatic notifications and actions based on data changes. This system is pivotal for data monitoring and real-time response in various scenarios.

https://docs.snowflake.com/en/guides-overview-alerts

Snowflake's capabilities extend to configuring Snowpipe for error notifications or using tasks for anomaly detection. Additionally, integrating with AWS SNS and Azure Event Grid can elevate your notification strategies to a new level.

Now, How about if we add a cool mobile and desktop push notification :) 

ntfy (Notify) for Mobile and Desktop Notifications

ntfy stands out as an innovative solution for sending notifications to mobile phones and desktops. This open-source tool, deployable on your own infrastructure, supports notifications via PUT/POST methods. It's compatible with Android, iOS, and web applications, ensuring a wide reach.

Setting up ntfy is straightforward:

Ensure Python and Docker are installed in your environment.

Download the server.yml file from the ntfy GitHub repository https://github.com/binwiederhier/ntfy/blob/main/server/server.yml

open the yml file and add your local or host IP address 
example: base-url: http://10.0.0.4
For iOS users, an additional line in the server.yml file is required for compatibility. 
upstream-base-url: https://ntfy.sh

Run the ntfy Docker container 

sudo docker run -p 80:80 -itd binwiederhier/ntfy serve


Using ntfy:

Once ntfy is operational, access its web interface, subscribe to a topic (e.g., DataAlerts), and send messages via terminal commands:

curl -d "Backup on $(hostname) complete" 10.0.0.4/DataAlerts

Integrating ntfy with Snowflake:

To demonstrate a real-world application, let's integrate ntfy with Snowflake using FastAPI to create an API layer. The API will receive messages and forward them to ntfy. The FastAPI script (Main.py) includes a simple endpoint to handle this process:

Main.py
from fastapi import FastAPI, Query
 import subprocess
app = FastAPI()
@app.get("/ntfyrun")
 def ntfyrun(message: str = Query(…, description="The message to send")):
 try:
 subprocess.run(["curl", "-d", message, "10.0.0.4/DataAlerts"], check=True)
 return {"message": f"Command executed with message: {message}"}
 except subprocess.CalledProcessError as e:
 return {"error": str(e)}


Let's Dockerize the FastAPI Main.py to run in the background.
Create a Dockerfile with the necessary instructions. here is the sample.


FROM python:3.11
 WORKDIR /usr/src/app
 COPY requirements.txt .
 RUN pip install - no-cache-dir -r requirements.txt # add library requirements in the txt file
 COPY . .
 CMD ["uvicorn", "main:app", " - host", "0.0.0.0", " - port", "8000"]


Build and run the Docker container:

sudo docker build -t ntfyapi .
sudo docker run -d -p 8000:8000 ntfyapi
Final Step - Snowflake Integration

Create a network rule in Snowflake:

CREATE OR REPLACE NETWORK RULE ntfy_api_network_rule
 MODE = EGRESS
 TYPE = HOST_PORT
 VALUE_LIST = ('10.0.0.4:8000'); -- use your public exposed IP for the API
https://docs.snowflake.com/en/user-guide/network-rules

Set up an external access integration:

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION ntfy_api_access_integration
 ALLOWED_NETWORK_RULES = (ntfy_api_network_rule)
 ENABLED = true;

Develop a function to connect to the API endpoint:

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
 
Executing SELECT Ntfy_Push_Notification("Message from Snowflake");
will trigger the notification process and all the mobile and desktop devices subscribed to the topic DataAlerts will get notifications pop-up and sound based on local settings.
With this setup, you can now use this UDF in tasks, alerts, and various other places in your Snowflake environment.
