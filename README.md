Analysis of Wildlife Strikes to Aircraft

This project is an academic practicum completed for the CS5200 course at Northeastern University during Summer Full 2024. It demonstrates relational database design, SQL query development, data ingestion from CSV, visualization in R, and the implementation of stored procedures with audit logging in MySQL.

📊 Project Overview

Objective: Analyze wildlife strike data reported by aircraft using a structured relational database hosted on a cloud-based MySQL instance.

Data Source: Provided CSV file BirdStrikesData-V4-SuF24.csv

Tools Used:

Languages: R, SQL

Database: MySQL (freemysqlhosting.net)

Libraries: RMySQL, DBI, dplyr, lubridate, kableExtra

🔧 Key Features

Designed a normalized schema with 4 related tables (airports, flights, conditions, incidents) and appropriate constraints.

Loaded, cleaned, and mapped raw CSV data into the schema using R code and SQL joins.

Queried and visualized data using R (e.g., total wildlife strikes per year, top airports/airlines).

Created a MySQL stored procedure to update incidents and log original values in an audit table (update_log).

Included inline documentation and structured R Notebook for reproducibility.

📈 Visualizations

Formatted tables using kableExtra

Yearly trend line plot using base R plot() with axis labels and data annotations

🔄 Stored Procedure

update_incident(...) stored procedure logs all updates to the incidents table by inserting a snapshot into the update_log table.

🗂 Repository Contents

AnalyzeData.RiggleD.Rmd – R Notebook containing all schema creation, data ingestion, queries, visualizations, and stored procedure logic.

.nb.html (coming soon) – Rendered HTML version of the R Notebook for easy viewing.

✅ How to View or Run

Clone the repo and open AnalyzeData.RiggleD.Rmd in RStudio.

Ensure required libraries are installed: RMySQL, DBI, dplyr, lubridate, kableExtra

Replace MySQL credentials with your own or set up an account on freemysqlhosting.net.

Knit the document or run chunks sequentially in RStudio.

Author: David C RiggleCourse: CS5200 – Database Management SystemsSemester: Summer Full 2024

This project was developed for educational purposes and demonstrates principles of relational database modeling, data wrangling, and R integration with MySQL.
