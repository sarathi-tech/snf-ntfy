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