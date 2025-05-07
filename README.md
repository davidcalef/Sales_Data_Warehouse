Sales Data Warehouse and Analysis

This project is an academic practicum completed for the CS5200 course at Northeastern University during Summer Full 2024. It demonstrates XML data ingestion, relational database design, SQL query development, analytical star-schema implementation, and data visualization in R.

📊 Project Overview

Objective: Transform pharmaceutical sales transaction data from XML files into a structured analytical data warehouse (star schema) and perform data analysis and visualization.

Data Source: Provided XML files (pharmaReps and pharmaSales transactions)

Tools Used:

Languages: R, SQL

Databases: SQLite (transactional storage), MySQL (star-schema data warehouse on freemysqlhosting.net)

Libraries: RSQLite, RMySQL, DBI, XML, ggplot2, kableExtra

🔧 Key Features

Designed and implemented a relational schema using SQLite to store products, customers, sales representatives, and sales transactions extracted from XML.

Created an analytical star schema in MySQL featuring dimension tables (customers_dim, products_dim, reps_dim) and fact tables (sales_facts, rep_facts) to optimize analytical queries.

Extracted, transformed, and loaded XML data into SQLite, then migrated relevant data into MySQL analytical tables.

Developed SQL-based analytical queries to provide insights such as top products by revenue, quarterly sales trends, and sales performance by representative.

Visualized data using ggplot2 (bar charts, line plots) and formatted tables with kableExtra in a structured R Notebook.

📈 Visualizations

Top five products by revenue (bar chart)

Revenue and units sold per product per quarter (facet-wrapped bar charts)

Revenue per product per country (line plot)

Average sales per sales representative per quarter (formatted table with kableExtra)

🗂 Repository Contents

LoadXML2DB.R – R script for loading and transforming XML data into a SQLite transactional database.

CreateStarSchema.R – R script for creating the star schema and populating the analytical database in MySQL.

AnalyzeData.RiggleD.Rmd – R Notebook containing analytical queries, visualizations, and structured documentation.

AnalyzeData.RiggleD.html (coming soon) – Rendered HTML version of the R Notebook for easy viewing hosted via GitHub Pages.

✅ How to View or Run

Clone the repository and open the files in RStudio.

Ensure required libraries are installed: RSQLite, RMySQL, DBI, XML, ggplot2, kableExtra, rprojroot.

Acquire XML data files separately and place them in the txn-xml folder within the project directory.

Run the LoadXML2DB.R script to populate the SQLite database.

Update MySQL connection credentials in CreateStarSchema.R and run the script to populate the analytical MySQL database.

Knit AnalyzeData.RiggleD.Rmd in RStudio to generate the analysis report.

Author: David C RiggleCourse: CS5200 – Database Management SystemsSemester: Summer Full 2024

This project was developed for educational purposes and demonstrates principles of database design, ETL processes, star-schema analytical modeling, and data visualization using R and SQL.


