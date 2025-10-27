from pyspark.sql import SparkSession
import os
from datetime import datetime
def init_spark():
    spark = SparkSession.builder.appName("lh-hms-cloud").enableHiveSupport().getOrCreate()
    return spark
def create_database(spark,bucket_name,catalog):
    spark.sql(f"create database if not exists {catalog}.<db_name> LOCATION 's3a://{bucket_name}/'")
def list_databases(spark,catalog):
    spark.sql(f"show databases from {catalog}").show()
def basic_iceberg_table_operations(spark,catalog):
    spark.sql(f"create table if not exists {catalog}.<db_name>.<table_name>(id INTEGER, name
    VARCHAR(10), age INTEGER, salary DECIMAL(10, 2)) using iceberg").show()
    spark.sql(f"insert into {catalog}.<db_name>.<table_name>
    values(1,'Alan',23,3400.00),(2,'Ben',30,5500.00),(3,'Chen',35,6500.00)")
    spark.sql(f"select * from {catalog}.<db_name>.<table_name>").show()
def clean_database(spark,catalog):
    spark.sql(f'drop table if exists {catalog}.<db_name>.<table_name> purge')
    spark.sql(f'drop database if exists {catalog}.<db_name> cascade')
def main():
    try:
        spark = init_spark()
        create_database(spark,"icebergibucket","spark_catalog")
        list_databases(spark,"spark_catalog")
        basic_iceberg_table_operations(spark,"spark_catalog")
    finally:
        #clean_database(spark,"spark_catalog")
        spark.stop()
if __name__ == '__main__':
    main()