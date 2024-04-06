#!/bin/bash

# Check if MySQL is installed
if ! command -v mysql &> /dev/null
then
    echo "MySQL is not installed. Installing..."
    sudo apt-get update
    sudo apt-get install mysql-server -y

    # Start MySQL service
    sudo service mysql start

    # Set up MySQL root password (replace 'your_password' with your desired password)
    sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'your_password'; FLUSH PRIVILEGES;"
else
    echo "MySQL is already installed."
fi

# Create a new database and table
mysql -u root -pyour_password -e "CREATE DATABASE IF NOT EXISTS mydatabase;"
mysql -u root -pyour_password mydatabase -e "CREATE TABLE IF NOT EXISTS mytable (column1 INT, column2 VARCHAR(255), column3 DATE);"

# Import data from CSV file into the table (replace 'data.csv' with your CSV file)
mysql -u root -pyour_password mydatabase -e "LOAD DATA INFILE '/path/to/your/data.csv' INTO TABLE mytable FIELDS TERMINATED BY ',' IGNORE 1 LINES;"

echo "Database setup complete."
