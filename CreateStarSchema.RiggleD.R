# David Riggle
# 8-5-2024
# Practicum II (Summer 2024) / Mine a Database
# Part 2 Create Star/Snowflake Schema

# Load required libraries
library(DBI)
library(RMySQL)
library(RSQLite)

# MySQL database connection details
mysql_host <- "sql5.freemysqlhosting.net"
mysql_dbname <- "sql5722857"
mysql_user <- "sql5722857"
mysql_password <- "RciB69Grhi"
mysql_port <- 3306

# SQLite database connection details
sqlite_dbname <- "pharma_sales.db"

# Connect to MySQL database
con_mysql <- dbConnect(
  RMySQL::MySQL(),
  dbname = mysql_dbname,
  host = mysql_host,
  port = mysql_port,
  user = mysql_user,
  password = mysql_password
)

# Ensure MySQL connection is closed on exit
on.exit(dbDisconnect(con_mysql), add = TRUE)

# Connect to SQLite database
con_sqlite <- dbConnect(RSQLite::SQLite(), sqlite_dbname)

# Ensure SQLite connection is closed on exit
on.exit(dbDisconnect(con_sqlite), add = TRUE)

# Verify SQLite tables
sqlite_tables <- dbListTables(con_sqlite)
required_tables <- c("customers", "reps", "sales_2020", "sales_2021", "sales_2022", "sales_2023")
missing_tables <- setdiff(required_tables, sqlite_tables)
if (length(missing_tables) > 0) {
  stop(paste("Missing tables in SQLite database:", paste(missing_tables, collapse = ", ")))
}

# Disable foreign key checks in MySQL to avoid errors when dropping tables
dbExecute(con_mysql, "SET FOREIGN_KEY_CHECKS = 0;")

# Drop existing tables in MySQL if they exist
dbExecute(con_mysql, "DROP TABLE IF EXISTS sales_facts")
dbExecute(con_mysql, "DROP TABLE IF EXISTS customers_dim")
dbExecute(con_mysql, "DROP TABLE IF EXISTS products_dim")
dbExecute(con_mysql, "DROP TABLE IF EXISTS reps_dim")
dbExecute(con_mysql, "DROP TABLE IF EXISTS rep_facts")

# Re-enable foreign key checks after dropping tables
dbExecute(con_mysql, "SET FOREIGN_KEY_CHECKS = 1;")

# Create dimension tables in MySQL
dbExecute(con_mysql, "
  CREATE TABLE customers_dim (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(255),
    country VARCHAR(255)
  );
")

dbExecute(con_mysql, "
  CREATE TABLE products_dim (
    product_name VARCHAR(255) PRIMARY KEY,
    unit_cost DOUBLE
  );
")

dbExecute(con_mysql, "
  CREATE TABLE reps_dim (
    rep_id VARCHAR(255) PRIMARY KEY,
    last_name VARCHAR(255),
    first_name VARCHAR(255),
    phone VARCHAR(255),
    hire_date DATE,
    commission DOUBLE,
    territory VARCHAR(255),
    certified BOOLEAN
  );
")

# Create sales_facts table in MySQL
dbExecute(con_mysql, "
  CREATE TABLE sales_facts (
    sales_id INT PRIMARY KEY AUTO_INCREMENT,
    txn_id VARCHAR(255),
    rep_id VARCHAR(255),
    customer_id INT,
    sale_date DATE,
    product_name VARCHAR(255),
    unit_cost DOUBLE,
    quantity INT,
    FOREIGN KEY (rep_id) REFERENCES reps_dim(rep_id),
    FOREIGN KEY (customer_id) REFERENCES customers_dim(customer_id),
    FOREIGN KEY (product_name) REFERENCES products_dim(product_name)
  );
")

# Insert data from SQLite to MySQL

# Insert customers
customers_data <- dbGetQuery(con_sqlite, "SELECT * FROM customers")
dbWriteTable(con_mysql, "customers_dim", customers_data, append = TRUE, row.names = FALSE)

# Insert reps
reps_data <- dbGetQuery(con_sqlite, "SELECT * FROM reps")
dbWriteTable(con_mysql, "reps_dim", reps_data, append = TRUE, row.names = FALSE)

# Insert products and sales from each year table
for (year in c("2020", "2021", "2022", "2023")) {
  table_name <- paste0("sales_", year)
  sales_data <- dbGetQuery(con_sqlite, paste0("SELECT * FROM ", table_name))
  
  # Insert products
  products_data <- unique(sales_data[, c("product_name", "unit_cost")])
  dbWriteTable(con_mysql, "products_dim", products_data, append = TRUE, row.names = FALSE, overwrite = FALSE)
  
  # Modify rep_id format to match reps_dim
  sales_data$rep_id <- paste0("r", sales_data$rep_id)
  
  # Verify if all rep_ids exist in reps_dim
  missing_reps <- setdiff(unique(sales_data$rep_id), unique(reps_data$rep_id))
  if (length(missing_reps) > 0) {
    cat("\nMissing rep_ids in reps_dim for year", year, ":\n")
    print(missing_reps)
  }
  
  # Filter sales_data to only include rows with valid rep_ids
  valid_sales_data <- sales_data[sales_data$rep_id %in% reps_data$rep_id, ]
  
  # Insert into sales_facts table
  if (nrow(valid_sales_data) > 0) {
    dbWriteTable(con_mysql, "sales_facts", valid_sales_data, append = TRUE, row.names = FALSE)
  }
}

# Create rep_facts table in MySQL
dbExecute(con_mysql, "
  CREATE TABLE rep_facts (
    rep_id VARCHAR(255),
    year INT,
    quarter INT,
    month INT,
    total_amount_sold DOUBLE,
    avg_amount_sold DOUBLE,
    PRIMARY KEY (rep_id, year, quarter, month),
    FOREIGN KEY (rep_id) REFERENCES reps_dim(rep_id)
  );
")

# Populate rep_facts table
rep_facts_query <- "
  INSERT INTO rep_facts (rep_id, year, quarter, month, total_amount_sold, avg_amount_sold)
  SELECT 
    s.rep_id,
    YEAR(s.sale_date) AS year,
    QUARTER(s.sale_date) AS quarter,
    MONTH(s.sale_date) AS month,
    SUM(s.quantity * s.unit_cost) AS total_amount_sold,
    AVG(s.quantity * s.unit_cost) AS avg_amount_sold
  FROM sales_facts s
  GROUP BY s.rep_id, year, quarter, month;
"

dbExecute(con_mysql, rep_facts_query)

# Verification queries
execute_and_print <- function(query, description) {
  cat("\n---", description, "---\n")
  result <- dbGetQuery(con_mysql, query)
  print(result)
}

# Verify Customers Data
execute_and_print("SELECT * FROM customers_dim LIMIT 5", "Customers Data")

# Verify Reps Data
execute_and_print("SELECT * FROM reps_dim LIMIT 5", "Reps Data")

# Verify Products Data
execute_and_print("SELECT * FROM products_dim LIMIT 5", "Products Data")

# Verify Sales Data
execute_and_print("SELECT * FROM sales_facts LIMIT 5", "Sales Data")

# Verify Aggregated Sales by Rep
execute_and_print("
  SELECT rep_id, COUNT(*) as sales_count
  FROM sales_facts
  GROUP BY rep_id
  ORDER BY sales_count DESC
  LIMIT 5;
", "Aggregated Sales by Rep")

# Verify Aggregated Sales by Product
execute_and_print("
  SELECT product_name, SUM(quantity) as total_quantity
  FROM sales_facts
  GROUP BY product_name
  ORDER BY total_quantity DESC
  LIMIT 5;
", "Aggregated Sales by Product")

# Verify Rep Facts Data
execute_and_print("SELECT * FROM rep_facts LIMIT 5", "Rep Facts Data")

# Close database connections
dbDisconnect(con_mysql)
dbDisconnect(con_sqlite)
