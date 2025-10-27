from pyspark.sql import SparkSession

# Create Spark session with Iceberg support
spark = SparkSession.builder \
    .appName("Read Iceberg Table") \
    .config("spark.sql.catalog.iceberg_data", "org.apache.iceberg.spark.SparkCatalog") \
    .config("spark.sql.catalog.iceberg_data.type", "hadoop") \
    .config("spark.sql.catalog.iceberg_data.warehouse", "path/to/warehouse") \
    .getOrCreate()

# Read the Iceberg table
df = spark.read.table("iceberg_data.hcd_users.users")

# Show the data
df.show()