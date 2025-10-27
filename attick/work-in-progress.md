CREATE KEYSPACE retail_ks WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1} ;
CREATE TABLE IF NOT EXISTS customer_orders_by_id
(customer_id uuid, order_id uuid, order_date timestamp, status text, PRIMARY KEY (customer_id, order_id));
mvn clean package
mvn exec:java -Dexec.mainClass="com.ibm.wxd.datalabs.demo.cass_spark_iceberg.LoadCustomerOrdersById"


{
  "application_details": {
    "application": "s3a://spark-artifacts/cass-spark-iceberg-1.2.jar",
    "class": "com.ibm.wxd.datalabs.demo.cass_spark_iceberg.CassandraToIceberg",
    "conf": {
      "spark.cassandra.connection.host": "host.containers.internal",
      "spark.cassandra.auth.username": "cassandra",
      "spark.cassandra.auth.password": "cassandra",
      "spark.sql.catalog.spark_catalog.warehouse": "s3a://spark-etl/",
      "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem",
      "spark.hadoop.fs.s3a.path.style.access": "true",
      "spark.hadoop.fs.s3a.bucket.spark-artifacts.secret.key": "dummyvalue",
      "spark.hadoop.fs.s3a.bucket.spark-artifacts.endpoint": "http://ibm-lh-minio-svc:9000",
      "spark.hadoop.fs.s3a.bucket.spark-artifacts.access.key": "dummyvalue",
      "spark.hadoop.fs.s3a.bucket.spark-artifacts.aws.credentials.provider": "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider",
      "spark.hadoop.fs.s3a.bucket.spark-etl.secret.key": "dummyvalue",
      "spark.hadoop.fs.s3a.bucket.spark-etl.endpoint": "http://ibm-lh-minio-svc:9000",
      "spark.hadoop.fs.s3a.bucket.spark-etl.access.key": "dummyvalue",
      "spark.hadoop.fs.s3a.bucket.spark-etl.aws.credentials.provider": "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider"
    }
  },
  "deploy_mode": "local"
}

{
  "application_details": {
    "application": "s3a://spark-artifacts/cass-spark-iceberg-1.2.jar",
    "class": "com.ibm.wxd.datalabs.demo.cass_spark_iceberg.CassandraToIceberg",
    "conf": {
      "spark.cassandra.connection.host": "host.containers.internal",
      "spark.cassandra.auth.username": "cassandra",
      "spark.cassandra.auth.password": "cassandra",
      "spark.sql.catalog.spark_catalog.warehouse": "./etl",
      "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem",
      "spark.hadoop.fs.s3a.path.style.access": "true",
      "spark.hadoop.fs.s3a.bucket.spark-artifacts.secret.key": "dummyvalue",
      "spark.hadoop.fs.s3a.bucket.spark-artifacts.endpoint": "http://ibm-lh-minio-svc:9000",
      "spark.hadoop.fs.s3a.bucket.spark-artifacts.access.key": "dummyvalue",
      "spark.hadoop.fs.s3a.bucket.spark-artifacts.aws.credentials.provider": "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider",
      "spark.hadoop.fs.s3a.bucket.spark-etl.secret.key": "dummyvalue",
      "spark.hadoop.fs.s3a.bucket.spark-etl.endpoint": "http://ibm-lh-minio-svc:9000",
      "spark.hadoop.fs.s3a.bucket.spark-etl.access.key": "dummyvalue",
      "spark.hadoop.fs.s3a.bucket.spark-etl.aws.credentials.provider": "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider"
    }
  },
  "deploy_mode": "local"
}



