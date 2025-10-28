# Star Schema and Queries Analysis - cass_spark_iceberg

## Overview

The `cass_spark_iceberg` project implements a classic **star schema** for OLAP (Online Analytical Processing) queries. This document provides a comprehensive analysis of the data model, transformation process, and analytical queries.

## Star Schema Architecture

A star schema consists of:
- **One central fact table** containing business metrics
- **Multiple dimension tables** containing descriptive attributes
- **Surrogate keys** for optimal join performance

### Schema Diagram

![star-schema](./assets/star-schema.png)

## Data Model Structure

### Fact Table: `fact_customer_order`

The central fact table contains the business metrics and foreign keys to dimension tables.

| Column | Type | Description |
|--------|------|-------------|
| `order_id` | UUID | Primary key - unique order identifier |
| `customer_key` | Long | Foreign key to dim_customer |
| `date_key` | String | Foreign key to dim_date (format: yyyyMMdd) |
| `status_key` | Long | Foreign key to dim_status |

### Dimension Tables

#### 1. `dim_customer`
| Column | Type | Description |
|--------|------|-------------|
| `customer_key` | Long | Surrogate key (auto-generated) |
| `customer_id` | UUID | Business key - original customer identifier |

#### 2. `dim_date`
| Column | Type | Description |
|--------|------|-------------|
| `date_key` | String | Surrogate key (format: yyyyMMdd) |
| `full_date` | Date | Actual date value |
| `year` | Integer | Year component |
| `quarter` | Integer | Quarter component |
| `month` | Integer | Month component |

#### 3. `dim_status`
| Column | Type | Description |
|--------|------|-------------|
| `status_key` | Long | Surrogate key (auto-generated) |
| `order_status` | String | Business values: "Created", "Rejected", "Billed", "Shipped", "Delivered" |

## Data Transformation Process

The ETL process is implemented in `CassandraToIceberg.java`:

### 1. Extract
```java
// Read data from Cassandra
String keyspace = "retail_ks";
String table = "customer_orders_by_id";
Dataset<Row> customerOrderDF = sparkUtil.readCassandraTable(spark, keyspace, table);
```

### 2. Transform

#### Create Dimension Tables
```java
// Customer Dimension
Dataset<Row> dimCustomerDF = customerOrderDF.select("customer_id").distinct()
    .withColumn("customer_key", monotonically_increasing_id());

// Date Dimension with hierarchical attributes
Dataset<Row> dimDateDF = customerOrderDF.select(col("order_date").as("full_date")).distinct()
    .withColumn("date_key", date_format(col("full_date"), "yyyyMMdd"))
    .withColumn("year", year(col("full_date")))
    .withColumn("quarter", quarter(col("full_date")))
    .withColumn("month", month(col("full_date")));

// Status Dimension
Dataset<Row> dimStatusDF = customerOrderDF.select(col("status").as("order_status")).distinct()
    .withColumn("status_key", monotonically_increasing_id());
```

#### Create Fact Table with Joins
```java
Dataset<Row> factCustomerOrderDF = customerOrderDF
    .join(dimCustomerLookUp, 
          customerOrderDF.col("customer_id").equalTo(dimCustomerLookUp.col("customer_id")), "inner")
    .join(dimDateLookUp, 
          customerOrderDF.col("order_date").equalTo(dimDateLookUp.col("full_date")), "inner")
    .join(dimStatusLookUp, 
          customerOrderDF.col("status").equalTo(dimStatusLookUp.col("order_status")), "inner")
    .select(
        customerOrderDF.col("order_id"),
        dimCustomerLookUp.col("customer_key"),
        dimDateLookUp.col("date_key"),
        dimStatusLookUp.col("status_key"));
```

### 3. Load
```java
// Write to Iceberg tables
dimCustomerDF.writeTo(icebergDimCustomer).using("iceberg").createOrReplace();
dimDateDF.writeTo(icebergDimDate).using("iceberg").createOrReplace();
dimStatusDF.writeTo(icebergDimStatus).using("iceberg").createOrReplace();
factCustomerOrderDF.writeTo(icebergFactCustomerOrder).using("iceberg").createOrReplace();
```

## OLAP Query Types

The project demonstrates various OLAP operations through `olap_queries.sql`:

### 1. Roll-Up (Aggregation)
Aggregates data to higher levels of hierarchy.

```sql
-- Orders by year and month (Roll-Up)
SELECT d.year, d.month, COUNT(f.order_id) AS order_count 
FROM spark_catalog.default.fact_customer_order f 
JOIN spark_catalog.default.dim_date d ON f.date_key = d.date_key 
GROUP BY d.year, d.month 
ORDER BY d.year DESC, d.month DESC;
```

### 2. Drill-Down (More Detail)
Provides more detailed view by adding dimensions or reducing aggregation.

```sql
-- Delivered orders by year (Drill-Down)
SELECT d.year, COUNT(f.order_id) 
FROM spark_catalog.default.fact_customer_order f 
JOIN spark_catalog.default.dim_date d ON f.date_key = d.date_key 
JOIN spark_catalog.default.dim_status s ON f.status_key = s.status_key 
WHERE s.order_status = 'Delivered' 
GROUP BY d.year 
ORDER BY d.year DESC;
```

### 3. Slice (Filter on One Dimension)
Focuses on specific dimension values.

```sql
-- Orders by status and year (Slice)
SELECT s.order_status, d.year, COUNT(f.order_id) AS order_count 
FROM spark_catalog.default.fact_customer_order f 
JOIN spark_catalog.default.dim_status s ON f.status_key = s.status_key 
JOIN spark_catalog.default.dim_date d ON f.date_key = d.date_key 
GROUP BY s.order_status, d.year 
ORDER BY d.year DESC, order_count DESC;
```

### 4. Dice (Filter on Multiple Dimensions)
Applies filters across multiple dimensions.

```sql
-- Orders for a specific customer (Dice)
SELECT c.customer_id, COUNT(f.order_id) AS order_count 
FROM spark_catalog.default.fact_customer_order f 
JOIN spark_catalog.default.dim_customer c ON f.customer_key = c.customer_key 
WHERE c.customer_id = '86f097c8-d5e0-435d-894d-8e73242ab4d6' 
GROUP BY c.customer_id;
```

### 5. Drill-Across (Multiple Dimensions)
Analyzes data across different dimension combinations.

```sql
-- Top 5 customers by order count (Drill-Across)
SELECT c.customer_id, COUNT(f.order_id) AS order_count 
FROM spark_catalog.default.fact_customer_order f 
JOIN spark_catalog.default.dim_customer c ON f.customer_key = c.customer_key 
GROUP BY c.customer_id 
ORDER BY order_count DESC LIMIT 5;
```

### 6. Time Series Analysis
Analyzes trends over time periods.

```sql
-- Monthly order trends for 'Shipped' status
SELECT date_format(d.full_date, 'yyyy-MM') AS order_month, 
       COUNT(f.order_id) AS monthly_orders 
FROM spark_catalog.default.fact_customer_order f 
JOIN spark_catalog.default.dim_date d ON f.date_key = d.date_key 
JOIN spark_catalog.default.dim_status s ON f.status_key = s.status_key 
WHERE s.order_status = 'Shipped' 
GROUP BY order_month 
ORDER BY order_month DESC;
```

### 7. Comparative Analysis
Compares metrics across different time periods.

```sql
-- Year-over-Year growth in orders
SELECT curr.year, curr.month, 
       curr.order_count AS current_year_orders, 
       COALESCE(prev.order_count, 0) AS previous_year_orders, 
       CASE WHEN COALESCE(prev.order_count, 0) = 0 THEN 100.0 
            ELSE ((curr.order_count - prev.order_count) / prev.order_count) * 100 
       END AS growth_percentage 
FROM (SELECT d.year, d.month, COUNT(f.order_id) AS order_count 
      FROM spark_catalog.default.fact_customer_order f 
      JOIN spark_catalog.default.dim_date d ON f.date_key = d.date_key 
      GROUP BY d.year, d.month) AS curr 
LEFT JOIN (SELECT d.year + 1 AS year, d.month, COUNT(f.order_id) AS order_count 
           FROM spark_catalog.default.fact_customer_order f 
           JOIN spark_catalog.default.dim_date d ON f.date_key = d.date_key 
           GROUP BY d.year, d.month) AS prev 
ON curr.year = prev.year AND curr.month = prev.month 
ORDER BY curr.year DESC, curr.month DESC;
```

### 8. Multi-Dimensional Analysis
Complex analysis across multiple dimensions.

```sql
-- Customer orders by non-Delivered status
SELECT c.customer_id, s.order_status, COUNT(f.order_id) AS order_count 
FROM spark_catalog.default.fact_customer_order f 
JOIN spark_catalog.default.dim_customer c ON f.customer_key = c.customer_key 
JOIN spark_catalog.default.dim_status s ON f.status_key = s.status_key 
WHERE s.order_status != 'Delivered' 
GROUP BY c.customer_id, s.order_status 
ORDER BY order_count DESC;
```

### 9. Aggregate Analysis
Statistical analysis of aggregated data.

```sql
-- Average orders per customer by year
SELECT d.year, AVG(customer_order_counts.order_count) AS avg_orders_per_customer 
FROM (SELECT c.customer_id, d.year, COUNT(f.order_id) AS order_count 
      FROM spark_catalog.default.fact_customer_order f 
      JOIN spark_catalog.default.dim_customer c ON f.customer_key = c.customer_key 
      JOIN spark_catalog.default.dim_date d ON f.date_key = d.date_key 
      GROUP BY c.customer_id, d.year) AS customer_order_counts 
JOIN spark_catalog.default.dim_date d ON customer_order_counts.year = d.year 
GROUP BY d.year 
ORDER BY d.year DESC;
```

### 10. Full Cube Analysis
Complete multi-dimensional analysis.

```sql
-- Inventory of all orders with customer, year, status by order-volume
SELECT c.customer_id, d.year, s.order_status, COUNT(f.order_id) AS order_count 
FROM spark_catalog.default.fact_customer_order f 
JOIN spark_catalog.default.dim_customer c ON f.customer_key = c.customer_key 
JOIN spark_catalog.default.dim_date d ON f.date_key = d.date_key 
JOIN spark_catalog.default.dim_status s ON f.status_key = s.status_key 
GROUP BY c.customer_id, d.year, s.order_status 
ORDER BY order_count DESC;
```

## Key Components

### Core Classes

| Class | Purpose |
|-------|---------|
| `CassandraToIceberg.java` | Main ETL process creating the star schema |
| `OlapApp.java` | Executes analytical queries |
| `QueryUtil.java` | Reads and parses SQL queries from resources |
| `CustomerOrderHelper.java` | Generates test data with realistic patterns |

### Data Transfer Objects (DTOs)

| DTO | Purpose |
|-----|---------|
| `CustomerOrder.java` | Represents the source data structure |
| `OlapQuery.java` | Encapsulates query information and SQL |

### Utility Classes

| Utility | Purpose |
|---------|---------|
| `SparkUtil.java` | Spark session and table operations |
| `CassUtil.java` | Cassandra connection utilities |

## Architecture Benefits

### 1. Performance
- **Denormalized structure** enables fast analytical queries
- **Surrogate keys** provide optimal join performance
- **Iceberg format** offers efficient columnar storage

### 2. Scalability
- **Iceberg ACID transactions** ensure data consistency
- **Schema evolution** supports changing requirements
- **Partitioning** optimizes query performance

### 3. Flexibility
- **Dimension tables** support various analytical perspectives
- **Hierarchical attributes** enable drill-down/roll-up operations
- **Multiple fact tables** can share dimension tables

### 4. Data Quality
- **Surrogate keys** ensure referential integrity
- **Type-safe joins** prevent data inconsistencies
- **Standardized dimension values** improve data quality

## Usage Examples

### Running the ETL Process
```bash
spark-submit --conf spark.cassandra.connection.host="localhost" \
  --conf spark.cassandra.auth.username="cassandra" \
  --conf spark.cassandra.auth.password="cassandra" \
  --conf spark.sql.catalog.spark_catalog.warehouse="./iceberg_dse_lh" \
  --master "local[1]" \
  --class com.ibm.wxd.datalabs.demo.cass_spark_iceberg.CassandraToIceberg \
  target/cass-spark-iceberg-1.2.jar
```

### Generating Test Data
```bash
mvn exec:java -Dexec.mainClass="com.ibm.wxd.datalabs.demo.cass_spark_iceberg.LoadCustomerOrdersById" \
  -Dexec.args="20 20"
```

## Conclusion

This implementation demonstrates a complete data warehouse pattern, transforming operational Cassandra data into an analytical star schema optimized for business intelligence and reporting. The star schema provides:

- **Fast query performance** through denormalized structure
- **Flexible analysis** through multiple dimension perspectives
- **Scalable architecture** using modern data lake technologies
- **Comprehensive OLAP operations** supporting various analytical needs

The project serves as an excellent example of how to migrate from operational databases to analytical data warehouses using Apache Spark and Apache Iceberg.
