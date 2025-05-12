# David Riggle
# 8-5-2024
# Practicum II (Summer 2024) / Mine a Database
# Part 1 Create Analytics Database and Load XML Data

# Load required libraries
library(RSQLite)
library(DBI)
library(XML)

# Define the path to the XML files relative to the project folder
xml_path <- "txn-xml/pharma-sales-v3"

# Check if the reps file exists before parsing
reps_file_path <- file.path(xml_path, "pharmaReps-Su24.xml")
if (!file.exists(reps_file_path)) {
  stop(paste("File does not exist:", reps_file_path))
}

# Load sales reps data
reps_xml <- xmlParse(reps_file_path)
reps_nodes <- getNodeSet(reps_xml, "//rep")

# Extract data from XML nodes
reps_data_transformed <- data.frame(
  rep_id = sapply(reps_nodes, function(x) paste0("r", xmlGetAttr(x, "rID"))),
  last_name = sapply(reps_nodes, function(x) xmlValue(xmlChildren(x[["demo"]])[["sur"]])),
  first_name = sapply(reps_nodes, function(x) xmlValue(xmlChildren(x[["demo"]])[["first"]])),
  phone = sapply(reps_nodes, function(x) xmlValue(xmlChildren(x[["demo"]])[["phone"]])),
  hire_date = as.Date(sapply(reps_nodes, function(x) xmlValue(xmlChildren(x[["demo"]])[["hiredate"]])), "%b %d %Y"),
  commission = as.numeric(gsub("%", "", sapply(reps_nodes, function(x) xmlValue(x[["commission"]])))) / 100,
  territory = sapply(reps_nodes, function(x) xmlValue(x[["territory"]])),
  certified = sapply(reps_nodes, function(x) !is.null(x[["certified"]]))
)

# Create a connection to the SQLite database
conn <- dbConnect(SQLite(), dbname = "pharma_sales.db")

# Ensure connection is closed on exit
on.exit(dbDisconnect(conn), add = TRUE)

# Drop existing tables if they exist
dbExecute(conn, "DROP TABLE IF EXISTS products")
dbExecute(conn, "DROP TABLE IF EXISTS reps")
dbExecute(conn, "DROP TABLE IF EXISTS customers")
dbExecute(conn, "DROP TABLE IF EXISTS sales")
dbExecute(conn, "DROP TABLE IF EXISTS sales_2020")
dbExecute(conn, "DROP TABLE IF EXISTS sales_2021")
dbExecute(conn, "DROP TABLE IF EXISTS sales_2022")
dbExecute(conn, "DROP TABLE IF EXISTS sales_2023")

# Create the tables
dbExecute(conn, "CREATE TABLE products (
    product_id INTEGER PRIMARY KEY AUTOINCREMENT,
    product_name TEXT UNIQUE,
    unit_cost REAL
);")

dbExecute(conn, "CREATE TABLE reps (
    rep_id TEXT PRIMARY KEY,
    last_name TEXT,
    first_name TEXT,
    phone TEXT,
    hire_date TEXT,
    commission REAL,
    territory TEXT,
    certified BOOLEAN
);")

dbExecute(conn, "CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_name TEXT,
    country TEXT
);")

dbExecute(conn, "CREATE TABLE sales (
    sales_id INTEGER PRIMARY KEY AUTOINCREMENT,
    txn_id TEXT,
    rep_id TEXT,
    customer_id INTEGER,
    sale_date TEXT,
    product_name TEXT,
    unit_cost REAL,
    quantity INTEGER,
    FOREIGN KEY (rep_id) REFERENCES reps(rep_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);")

# Insert reps data into the database
dbWriteTable(conn, "reps", reps_data_transformed, append = TRUE, row.names = FALSE)

# Load sales transactions data
sales_xml_files <- list.files(xml_path, pattern = "pharmaSalesTxn.*\\.xml", full.names = TRUE)

# Debugging: Print the list of XML files found
print("Sales XML files found:")
print(sales_xml_files)

# Define a function to parse sales transaction XML files
parse_sales_xml <- function(file) {
  xml_data <- xmlParse(file)
  txn_nodes <- getNodeSet(xml_data, "//txn")
  data.frame(
    txn_id = sapply(txn_nodes, function(x) xmlGetAttr(x, "txnID")),
    rep_id = sapply(txn_nodes, function(x) paste0("r", xmlGetAttr(x, "repID"))),
    customer = sapply(txn_nodes, function(x) xmlValue(xmlChildren(x)[["customer"]])),
    country = sapply(txn_nodes, function(x) xmlValue(xmlChildren(x)[["country"]])),
    date = as.Date(sapply(txn_nodes, function(x) xmlValue(xmlChildren(xmlChildren(x)[["sale"]])[["date"]])), "%m/%d/%Y"),
    product = sapply(txn_nodes, function(x) xmlValue(xmlChildren(xmlChildren(x)[["sale"]])[["product"]])),
    unitcost = sapply(txn_nodes, function(x) as.numeric(xmlValue(xmlChildren(xmlChildren(x)[["sale"]])[["unitcost"]]))),
    qty = sapply(txn_nodes, function(x) as.numeric(xmlValue(xmlChildren(xmlChildren(x)[["sale"]])[["qty"]])))
  )
}

# Load and combine sales data from all XML files
sales_data <- do.call(rbind, lapply(sales_xml_files, parse_sales_xml))

# Debugging: Print structure and summary of sales_data
print(str(sales_data))
print(summary(sales_data))

# Check if all expected columns are present
expected_cols <- c("txn_id", "rep_id", "customer", "country", "date", "product", "unitcost", "qty")
missing_cols <- setdiff(expected_cols, names(sales_data))
if (length(missing_cols) > 0) {
  stop(paste("Missing columns in sales_data:", paste(missing_cols, collapse = ", ")))
}

# Extract unique customers from sales data
customers_data <- unique(data.frame(
  customer_name = sales_data$customer,
  country = sales_data$country
))

# Insert customers data into database
dbWriteTable(conn, "customers", customers_data, append = TRUE, row.names = FALSE)

# Add customer_id to sales_data
sales_data$customer_id <- match(sales_data$customer, customers_data$customer_name)

# Extract unique products from sales data and insert into products table
products_data <- unique(data.frame(
  product_name = sales_data$product,
  unit_cost = sales_data$unitcost
))

# Insert products data into database
dbWriteTable(conn, "products", products_data, append = TRUE, row.names = FALSE)

# Insert sales data into the database
sales_data_transformed <- data.frame(
  txn_id = sales_data$txn_id,
  rep_id = sales_data$rep_id,
  customer_id = sales_data$customer_id,
  sale_date = format(sales_data$date, "%Y-%m-%d"),  # Format date as text
  product_name = sales_data$product,
  unit_cost = as.numeric(sales_data$unitcost),
  quantity = as.numeric(sales_data$qty)
)

# Debugging: Print structure and summary of sales_data_transformed
print(str(sales_data_transformed))
print(summary(sales_data_transformed))

dbWriteTable(conn, "sales", sales_data_transformed, append = TRUE, row.names = FALSE)

# Verify date format in sales table
print("Sample sale_date values:")
print(dbGetQuery(conn, "SELECT sale_date FROM sales LIMIT 10"))

# Ensure sale_date is properly formatted as text for partitioning
dbExecute(conn, "UPDATE sales SET sale_date = strftime('%Y-%m-%d', sale_date)")

# Partition data by year and insert into separate tables
years <- unique(format(as.Date(sales_data_transformed$sale_date), "%Y"))

for (year in years) {
  table_name <- paste0("sales_", year)
  year_data <- dbGetQuery(conn, paste0("SELECT * FROM sales WHERE strftime('%Y', sale_date) = '", year, "'"))
  print(paste("Data being inserted into table:", table_name))
  print(year_data)
  dbExecute(conn, paste0("CREATE TABLE ", table_name, " AS SELECT * FROM sales WHERE strftime('%Y', sale_date) = '", year, "'"))
}

# Verify data in partitioned tables
for (year in years) {
  table_name <- paste0("sales_", year)
  print(paste("Data in table:", table_name))
  print(dbGetQuery(conn, paste0("SELECT * FROM ", table_name, " LIMIT 5")))
}

# Drop the original sales table
dbExecute(conn, "DROP TABLE sales")

# Close the database connection
dbDisconnect(conn)
