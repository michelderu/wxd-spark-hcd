# Converged workloads with IBM watsonx.data and Datastax HCD

## 1. Overview

**Purpose:**  
Facilitate seamless integration of DataStax HCD (Cassandra) to manage extensive operational workloads, using wx.d for enhanced governed analytics capabilities.

![wxd-infrastructure-manager](./assets/wxd-infrastructure-manager.png)

**Scope:**  
Covers installation of watsonx.data and HCD, and the use of Spark to synchronize real-time data with an Iceberg table.

**Audience:**  
Targeted towards Developers, Customer Engineers, and Pre-sales professionals.

## 2. Prerequisites

System Requirements:
- Architecture: x86_64 or ARM64
- Cores: Minimum 12
- Memory: Minimum 16GB RAM (recommended 24GB)
- Disk Space: Minimum 100GB free space

Supported platforms:
- macOS (Intel or Apple Silicon)
- Windows 10/11 64-bit

## 3. Installation Steps

### A. Start IBM watsonx.data Developer Edition

Follow the [IBM watsonx.data Developer Edition installation steps](https://www.ibm.com/docs/en/watsonxdata/standard/2.2.x?topic=developer-edition-new-version). It will take a while before everything is configured and installed, please be patient.

You can check the pods to make sure all are running:
```bash
kubectl get pods -n wxd
kubectl get pods -n wxd | wc -l # should return 31
```

Finally expose the IBM watsonx.data Developer Edition UI:
```bash
export KUBECONFIG=~/.kube/config && nohup kubectl port-forward -n wxd service/lhconsole-ui-svc 6443:443 --address 0.0.0.0 > /dev/null 2>&1 &
```

Test IBM watsonx.data Developer Edition by navigating to [https://localhost:6443/](https://localhost:6443/) and logging in with `ibmhladmin` / `password`.

![wxd-homepage](./assets/wxd-homepage.png)

In case you want access to MinIO and MDS:
```bash
export KUBECONFIG=~/.kube/config && nohup kubectl port-forward -n wxd service/ibm-lh-minio-svc 9001:9001 --address 0.0.0.0 > /dev/null 2>&1 &
export KUBECONFIG=~/.kube/config && nohup kubectl port-forward -n wxd service/ibm-lh-mds-thrift-svc 8381:8381 --address 0.0.0.0 > /dev/null 2>&1 &
```
See the [IBM watsonx.data documentation](https://www.ibm.com/docs/en/watsonxdata/standard/2.2.x?topic=administering-exposing-minio-service) for more information.

Navigate to [http://localhost:9001/](http://localhost:9001/) and use username / password for MinIO: dummyvalue / dummyvalue.

![minio-homepage](./assets/minio-homepage.png)

### B. Start DataStax Hyper-Converged Database

Download the [tarball](http://downloads.datastax.com/hcd/hcd-1.2.3-bin.tar.gz) and unzip.

When using with Java 17, please set `CASSANDRA_JDK_UNSUPPORTED=true`.
Start with:
```bash
export JAVA_HOME="$(/usr/libexec/java_home -v17)"
export PATH="$JAVA_HOME/bin:$PATH"
export CASSANDRA_JDK_UNSUPPORTED=true
./hcd-1.2.3/bin/hcd cassandra
```

Look for:
> INFO  [main] 2025-10-27 13:40:24,500 HcdDaemon.java:22 - HCD startup complete

Test if all works well:
```bash
./hcd-1.2.3/bin/hcd cqlsh -u cassandra -p cassandra
```

You should be able to log in. Type `quit` to exit.

Load some sample data:
```bash
cqlsh -f sample-data.cql
```

### C. Add HCD to watsonx.data
1. Navigate to [https://localhost:6443/#/infrastructure-manager](https://localhost:6443/#/infrastructure-manager) and click `Add component'
2. Select `Cassandra` as a data source, click `Next`. Use the following configuraton details:
    - Display name: HCD
    - Hostname: host.containers.internal
    - Portname: 9042
    - Username: cassandra
    - Password: cassandra
    - Select 'Associate catalog'
    - Catalog name: hcd

Test to see if the sample data is available:
1. Click the `hcd` catalog
2. Click `Data Objects`
3. Expand `sample_ks` and click `users` in the Catalog browser
4. Click `Data sample` and confirm the 3 users are present

![wxd-data-manager](./assets/wxd-data-manager.png)

## Federated analytics
The first converged data integration is based on federated analytics using Presto as a query engine.

1. First associate the `hcd` catalog with Presto by clicking `Presto`
    - Click `Manage associations`
    - Add `hcd`, then `Save and restart engine`

2. Now you can start querying your operational data in the analytical environment of watsonx.data:
    - Open `Query workspace` on the left hand side
    - Ensure `Presto` is selected as the active engine
    - Run the following query `SELECT * from hcd.sample_ks.users`

![wxd-query-workspace](./assets/wxd-query-workspace.png)

Done! You have just queried Cassandra using SQL through the Presto Query Engine!

## Materialized analytics using wx.d CTAS
Federated analytics can be stressful on an operational system that handle massive workloads and requires low latencies. Hence it can be helpful to materialize the data into a governed catalog with associated Parquet files. This concept is called *Data Offloading* within watsonx.data.

With fit-for-purpose engines, data warehousing costs can be reduced by offloading workloads from a data warehouse to watsonx.data. Specifically,
applications that need to access this data can query it through Presto (or Spark). This includes being able to combine the offloaded data with the data that remains in the warehouse.

1. First create a new schema in Iceberg
    - Click `Data manager`, `Create` and then `Create schema`, select:
        - Catalog: iceberg_data
        - Name: hcd_users

2. Now transfer the data from the operational database to the analytical Iceberg table
    - Click `Query workspace` and click `+` to create a new query tab
    - Use the following CTAS (Create Table As) query
        ```sql
        create table iceberg_data.hcd_users.users as
        select * from hcd.sample_ks.users;
        ```
        ![wxd-query-manager-ctas](./assets/wxd-query-workspace-ctas.png)

3. Test it all works!
    - Click `Query workspace` and click `+` to create a new query tab
    - Run the following query on the analytical catalog:
        ```
        select * from iceberg_data.hcd_users.users
        ```

        ![wxd-query-manager-iceberg](./assets/wxd-query-workspace-iceberg.png)

# Utilizing the Spark engine for Materialized analytics
A lot of DataStax DSE customers have a use-case for Spark on top of their operational data and have been using DSE Analytics as a Spark engine. Now with watsonx.data the synergy between operational and analytical processing can be provided easily when using  Hyper-Converged Database (HCD) as well.

1. First create a new Spark engine
    - Click `Infrastructure manager` select `IBM Spark` and click `Next`
        - Display name: Spark
        - Associated catalogs: iceberg_data
    - Click `Create`

2. Clone the excellent [example by Pravin Bhat](https://github.ibm.com/pravin-bhat/cass_spark_iceberg)
    - Update your Cassandra connection settings as required in file `CassUtil.java` in function `getLocalCQLSession()`
    - Build the package by `mvn clean package`

3. Generate some sample data
    - Generate sample data by `mvn exec:java -Dexec.mainClass="com.ibm.wxd.datalabs.demo.cass_spark_iceberg.LoadCustomerOrdersById"`
    - You can check data creation either in watsonx.data's Query workspace or through `./hcd-1.2.3/bin/cqlsh` by running `select * from retail_ks.customer_orders_by_id;`

4. Prepare MinIO S3 buyckets and provide the Spark OLAP app
    - Ensure the MinIO service is port-forwarded to your localhost (see [A. Start IBM watsonx.data Developer Edition](#a-start-ibm-watsonxdata-developer-edition))
    - Create two buckets called `olap` and `spark-artifacts`
    - Copy the JAR-file `cass-spark-iceberg-1.2jar` to the `spark-artifacts` bucket

5. Run the OLAP job
    - Navigate to `wx.d Infrastructure manager` and click your `Spark` engine
    - Click `Applications` and click `Create application +`
    - Click `Payload` and paste the following configuration:
    ```json
    {
        "application_details": {
            "application": "s3a://spark-artifacts/cass-spark-iceberg-1.2.jar",
            "class": "com.ibm.wxd.datalabs.demo.cass_spark_iceberg.CassandraToIceberg",
            "conf": {
                "spark.cassandra.connection.host": "host.containers.internal",
                "spark.cassandra.auth.username": "cassandra",
                "spark.cassandra.auth.password": "cassandra",
                "spark.sql.catalog.spark_catalog.warehouse": "s3a://olap/",
                "spark.hadoop.fs.s3a.impl": "org.apache.hadoop.fs.s3a.S3AFileSystem",
                "spark.hadoop.fs.s3a.path.style.access": "true",
                "spark.hadoop.fs.s3a.bucket.spark-artifacts.endpoint": "http://ibm-lh-minio-svc:9000",
                "spark.hadoop.fs.s3a.bucket.spark-artifacts.access.key": "dummyvalue",
                "spark.hadoop.fs.s3a.bucket.spark-artifacts.secret.key": "dummyvalue",
                "spark.hadoop.fs.s3a.bucket.spark-artifacts.aws.credentials.provider": "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider",
                "spark.hadoop.fs.s3a.bucket.olap.endpoint": "http://ibm-lh-minio-svc:9000",
                "spark.hadoop.fs.s3a.bucket.olap.access.key": "dummyvalue",
                "spark.hadoop.fs.s3a.bucket.olap.secret.key": "dummyvalue",
                "spark.hadoop.fs.s3a.bucket.olap.aws.credentials.provider": "org.apache.hadoop.fs.s3a.SimpleAWSCredentialsProvider"
            }
        },
        "deploy_mode": "local"
    }
    ```
    - Execute the logs watcher through `./spark-logs.sh` and keep watching that window. This will print the logs from the Spark pod that runs je OLAP job
    - Now run the job by clicking `Submit application`

## References used throughout
- https://www.ibm.com/docs/en/watsonxdata/standard/2.2.x?topic=developer-edition-new-version
- https://github.ibm.com/Data-Labs/wx.d-developers-edition-add-hcd
- https://github.ibm.com/pravin-bhat/cass_spark_iceberg
- https://sinrega.org/2024-03-06-enabling-containers-gpu-macos

## Troubleshooting

### Podman on Apple Silicon
There is an issue when LibKrun is being used by Podman Desktop on Apple Silicon (M type machines). It depends on krunkit, which on Apple Silicon is limited to 8 cores. While watsonx.data Developer edition requires at least 10 cores. With LibKrun the start up of the wxd machine fails.

Switching to applehv offers:

✅ Benefits of Switching to applehv
- No hard-coded 8-core limit: Apple’s Hypervisor Framework (applehv) is more flexible in terms of CPU allocation. It allows Podman machines to use more than 8 cores, depending on your system’s actual capacity.
- Stable and native: It’s the default hypervisor backend on macOS and is well-supported by Apple.
- Better compatibility: Especially for workloads that don’t require GPU passthrough or advanced device emulation.

⚠️ Trade-offs Compared to libkrun
- No GPU passthrough: libkrun supports GPU acceleration via virtio-gpu and Venus/MoltenVK, which is not available with applehv.
- Less isolation: libkrun offers more advanced process isolation features, which are useful for confidential workloads.
- Less control over VM internals: applehv is a lower-level API and doesn’t expose as many customization options as libkrun.

### wx.d memory utilization
The default machine that gets created is called podman-wxd, with 10 cores and 16 GB of memory. 16 GB is a bit low as mostly 98% is being utilized. To provide a more healthy environment, we can create this machine up-front and the wx.d installer will re-use it.

```bash
podman machine stop
export CONTAINERS_MACHINE_PROVIDER=applehv
podman machine init --cpus 10 --memory 24576 --rootful podman-wxd
podman machine start podman-wxd
```

### Spark OLAP step missing keyspace and table
It might be that the step of creating sample data in [Utilizing the Spark engine for Materialized analytics](#utilizing-the-spark-engine-for-materialized-analytics) fails due to no keyspace and table available. Simply solve that by running the following in `./hcd-1.2.3/bin/cqlsh`:
```sql
CREATE KEYSPACE retail_ks WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1} ;
CREATE TABLE IF NOT EXISTS customer_orders_by_id (customer_id uuid, order_id uuid, order_date timestamp, status text, PRIMARY KEY (customer_id, order_id)) ;
```