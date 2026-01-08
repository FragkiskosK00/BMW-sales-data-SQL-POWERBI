# BMW-sales-data-SQL-POWERBI
# SQL Server → Power BI Star Schema Dashboard

## Project Overview
This project demonstrates an end-to-end BI workflow:
- CSV ingestion
- Data modeling in SQL Server
- Star schema design (Fact & Dimension tables)
- Power BI dashboard built on top of the model

The goal is to showcase data engineering and BI fundamentals using real-world practices.

---

## Architecture
CSV → SQL Server → Star Schema → Power BI

---

## Data Model - Star Schema
- Fact table: [fact_sales]
- Dimension tables:
  - dim_year
  - dim_region
  - dim_color
  - dim_model
  - dim_sales_classsification
  - dim_transmission
  - dim_fuel

---

## Tools & Technologies
- SQL Server
- T-SQL
- Power BI
- Star Schema modeling
- GitHub

---

## Dashboard -  Star schema

<img width="1112" height="622" alt="image" src="https://github.com/user-attachments/assets/c592912d-1acb-48a6-82a6-11eb40259391" />

<img width="1053" height="666" alt="image" src="https://github.com/user-attachments/assets/096de39f-5ca6-4c62-87f8-27cd9433639f" />

---

## How to Run
1. Import CSV from `/data`
2. Execute SQL scripts in `/sql`
3. Open `bmwpowerbi.pbix`
4. Update SQL Server connection if needed

---

## Key Concepts Demonstrated
- Data modeling
- Fact & dimension design
- SQL transformations
- BI visualization best practices

## Important notices
-  Update database name if needed
- Update CSV file path before running BULK INSERT
- No credentials are required
