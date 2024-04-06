#!/bin/bash

# Configuration Variables
DATABASE_NAME="smoking_data"
TABLE_NAME="smoking"
CSV_PATH="./smoking.csv"

install_sql() {
    if ! mysql --version &>/dev/null; then
        echo "MySQL Server not found."
        echo "Starting MySQL installation process..."

        # Update package lists
        if ! sudo apt-get update; then
            echo "Error: Failed to update package lists"
            exit 1
        fi

        # Install MySQL Server
        if ! sudo apt-get install -y mysql-server; then
            echo "Error: Failed to install MySQL Server"
            exit 1
        fi

        # Start MySQL Service
        if ! sudo systemctl start mysql.service; then
            echo "Error: Failed to start MySQL service"
            exit 1
        fi

        echo "MySQL Server installed and started successfully."
    else
        echo "MySQL Server is already installed."
    fi
}

install_sql

# Resetting root password
if ! sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY ''; FLUSH PRIVILEGES;"; then
    echo "Error: Failed to reset MySQL root password."
    exit 1
fi

# Function to enable local_infile
enable_local_infile() {
    echo "Enabling local_infile..."
    if ! sudo mysql -uroot -e "SET GLOBAL local_infile = 1;"; then
        echo "Error: Failed to enable local_infile."
        exit 1
    fi
}

# Function to check and enable local_infile if necessary
check_and_enable_local_infile() {
    local_infile_status=$(echo "SHOW GLOBAL VARIABLES LIKE 'local_infile';" | sudo mysql -u root | grep 'local_infile' | awk '{ print $2 }')

    if [ "$local_infile_status" = "ON" ]; then
        echo "local_infile is already enabled."
    else
        enable_local_infile
    fi
}

echo "Checking if local_infile is enabled..."
check_and_enable_local_infile

# Ensuring the CSV file exists before importing
if [ ! -f "$CSV_PATH" ]; then
    echo "CSV file $CSV_PATH not found."
    exit 1
fi

# Creating the database if it does not exist
if ! sudo mysql --local-infile=1 -uroot -e "CREATE DATABASE IF NOT EXISTS $DATABASE_NAME;"; then
    echo "Error: Failed to create database $DATABASE_NAME."
    exit 1
fi

# Checking if the table exists, and either creating it or truncating it as needed
if ! mysql -uroot -e "USE $DATABASE_NAME; DESCRIBE $TABLE_NAME;" &> /dev/null; then
    echo "The table $TABLE_NAME does not exist, creating it..."
    if ! mysql -uroot -e "USE $DATABASE_NAME; CREATE TABLE IF NOT EXISTS $TABLE_NAME (
        gender VARCHAR(10), 
        age INT, 
        marital_status VARCHAR(20), 
        highest_qualification VARCHAR(50), 
        nationality VARCHAR(50), 
        ethnicity VARCHAR(50), 
        gross_income VARCHAR(50), 
        region VARCHAR(50), 
        smoke VARCHAR(5), 
        amt_weekends FLOAT, 
        amt_weekdays FLOAT, 
        type VARCHAR(50)
    );"; then
        echo "Error: Failed to create table $TABLE_NAME."
        exit 1
    fi
else
    echo "The table $TABLE_NAME exists, truncating it before new import..."
    if ! mysql -uroot -e "USE $DATABASE_NAME; TRUNCATE TABLE $TABLE_NAME;"; then
        echo "Error: Failed to truncate table $TABLE_NAME."
        exit 1
    fi
fi

# Importing data from the CSV file into the table
if ! mysql -uroot --local-infile=1 -e "USE $DATABASE_NAME; LOAD DATA LOCAL INFILE '$CSV_PATH' INTO TABLE $TABLE_NAME FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;"; then
    echo "Error: Failed to import data from $CSV_PATH into $TABLE_NAME."
    exit 1
fi

echo "Database setup and data import for $DATABASE_NAME complete."

