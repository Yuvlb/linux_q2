#!/bin/python3

from flask import Flask, request
import subprocess

app = Flask(__name__)

@app.route('/', methods=['GET'])
def get():
    return "Usage: Send a POST request with an SQL query to process on the MySQL database."

@app.route('/', methods=['POST'])
def post():
    received_value = str(request.get_data(as_text=True))  # Gets the data from the POST request
    answer = calculate_answer(received_value)
    return str(answer)  # Returns the data to the user

def calculate_answer(received_value):
    # The command to execute the SQL query using mysql command-line tool
    command = ["mysql", "-uroot", "-e", received_value, "smoking_data"]
    
    try:
        # Execute the SQL command
        result = subprocess.run(command, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return result.stdout
    except subprocess.CalledProcessError as e:
        # Handle errors in SQL command execution
        return f"Error executing query: {e.stderr}"

if __name__ == "__main__":
    app.run(host='0.0.0.0')
