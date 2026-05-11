# 🚀 IBM x DataStax for Converged workloads

<div align="center">

![IBM watsonx.data](https://img.shields.io/badge/IBM-watsonx.data-blue?style=for-the-badge&logo=ibm)
![DataStax HCD](https://img.shields.io/badge/DataStax-HCD-purple?style=for-the-badge&logo=datastax)
![Apache Spark](https://img.shields.io/badge/Apache-Spark-orange?style=for-the-badge&logo=apache-spark)
![Apache Iceberg](https://img.shields.io/badge/Apache-Iceberg-blue?style=for-the-badge&logo=apache)

*Upgrade from operational Cassandra to AI-ready analytics and governance with watsonx.data*


</div>

---

## 📋 Table of Contents

- [🎯 Overview](#-overview)
- [⚙️ Prerequisites](#️-prerequisites)
- [🔧 Installation Steps](#-installation-steps)
  - [A. IBM watsonx.data Developer Edition](#a-ibm-watsonxdata-developer-edition)
  - [B. DataStax Hyper-Converged Database](#b-datastax-hyper-converged-database)
  - [C. Add HCD to watsonx.data](#c-add-hcd-to-watsonxdata)
- [🔍 Federated Analytics](#-federated-analytics)
- [📊 Materialized Analytics using wx.d CTAS](#-materialized-analytics-using-wxd-ctas)
- [⚡ Utilizing the Spark Engine](#-utilizing-the-spark-engine-for-materialized-analytics)
- [📚 References](#-references)
- [🛠️ Troubleshooting](#️-troubleshooting)

---

## 🎯 Overview

<div align="center">

![wxd-infrastructure-manager](./assets/wxd-infrastructure-manager.png)

</div>

### 🎯 Purpose
Facilitate seamless integration of **DataStax HCD (Cassandra)** to manage extensive operational workloads, using **IBM watsonx.data** for enhanced governed analytics capabilities.

### 📖 Scope
This guide covers:
- ✅ Installation of IBM watsonx.data Developer Edition
- ✅ Setup of DataStax Hyper-Converged Database (HCD)
- ✅ Integration between operational and analytical systems
- ✅ Real-time data synchronization using Apache Spark
- ✅ Materialized analytics with Apache Iceberg tables

### 👥 Target Audience
- 🧑‍💻 **Developers** - Implementation and integration
- 🔧 **Customer Engineers** - Solution deployment
- 💼 **Pre-sales Professionals** - Solution demonstration

## ⚙️ Prerequisites

### 💻 System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **Architecture** | x86_64 or ARM64 | x86_64 or ARM64 |
| **CPU Cores** | 10 cores | 16 cores |
| **Memory** | 16GB RAM | 24GB RAM |
| **Disk Space** | 150GB free | 200GB+ free |

### 🖥️ Supported Platforms
- 🍎 **macOS** (Intel or Apple Silicon)
- 🪟 **Windows 10/11** 64-bit
- 🐧 **Linux** (Ubuntu 20.04+, RHEL 8+, Fedora 43+)

### 📦 Required Software
- **Docker/Podman** - Container runtime
- **Kubernetes** - Container orchestration
- **Java 11 or 17** - For DataStax HCD
- **Maven** - For building Java applications

---

## 🔧 Installation Steps

### A. Container runtime

Ensure you have you runtime of choice set-up. Refer to [Containder Fundamentals](https://github.com/michelderu/container-fundamentals) and the specific setup instructions for your architecture [here](https://github.com/michelderu/container-fundamentals/blob/main/course/08-setup-linux-macos-windows.md).

### B. IBM watsonx.data Developer Edition

> ⏱️ **Installation Time**: The setup process may take 15-30 minutes depending on your system performance.

1. **📥 Download & Install**  
   Follow the [IBM watsonx.data Developer Edition installation steps](https://www.ibm.com/docs/en/watsonxdata/standard/2.3.x?topic=developer-edition-new-version).  
   
   > [!NOTE]
   > Alternatively you can follow the DIY instructions [here](./wxd-manual-install.md).

2. **🔍 Verify Installation**  
   Watch pods initializing:
   ```bash
   watch kubectl get pods -n wxd
   ```

   After a while, depending on your system this can take anything between a few minutes and 10's of minutes, you should see a similar status:

   ```text
   NAME                                              READY   STATUS      RESTARTS   AGE
   generate-certs-and-truststore-lwmm6               0/1     Completed   0          11m
   ibm-lh-control-plane-prereq-45hl9                 0/1     Completed   0          10m
   ibm-lh-mds-rest-7cc9bd5c9b-px5xw                  1/1     Running     0          8m52s
   ibm-lh-mds-thrift-679698fd56-22ldx                1/1     Running     0          8m52s
   ibm-lh-minio-7b6dfc69f8-88xgh                     1/1     Running     0          8m52s
   ibm-lh-presto-5d8bfdbd77-892cw                    1/1     Running     0          8m52s
   ibm-lh-validator-7877c94d95-j47qx                 1/1     Running     0          8m52s
   image-pull-job-wzxfv                              0/1     Completed   0          8m51s
   lhams-api-64874857bc-wndfz                        1/1     Running     0          8m53s
   lhconsole-api-6767df9d79-xjxq4                    1/1     Running     0          8m53s
   lhconsole-nodeclient-84fbc5b998-kb4pj             1/1     Running     0          8m53s
   lhconsole-ui-79bd784dc9-zxmz2                     1/1     Running     0          8m52s
   lhingestion-api-846498cb98-ntlm5                  1/1     Running     0          8m52s
   spark-hb-control-plane-975c76d8-qmkd9             2/2     Running     0          8m51s
   spark-hb-create-trust-store-9d577b768-2gsds       1/1     Running     0          9m9s
   spark-hb-deployer-agent-c5444448c-kpzmd           2/2     Running     0          8m51s
   spark-hb-load-postgres-db-specs-vgwrz             0/1     Completed   0          9m9s
   spark-hb-nginx-8647978c8-g69fv                    1/1     Running     0          8m51s
   spark-hb-register-hb-dataplane-6dd49b8f84-v9lbd   1/1     Running     0          5m36s
   spark-hb-ui-c5bb88ccd-vjmhf                       1/1     Running     0          8m51s
   wxd-pg-postgres-0                                 1/1     Running     0          10m
   ```

3. **🌐 Expose the UI**  
   Forwarding on `0.0.0.0` lets other hosts reference your machine IP:

   ```bash
   nohup kubectl port-forward -n wxd service/lhconsole-ui-svc 6443:443 --address 0.0.0.0 2>&1 &
   ```

4. **✅ Test Access**  
   Navigate to [https://localhost:6443/](https://localhost:6443/) (Expect a browser warning for the Development/TLS certificate) and log in with the defaults (unless you changed them):
   - **Username**: `ibmlhadmin`
   - **Password**: `password`

   <div align="center">
   
   ![wxd-homepage](./assets/wxd-homepage.png)
   
   </div>

5. **🔧 Optional: Access MinIO and MDS**
   ```bash
   # MinIO (Object Storage)
   nohup kubectl port-forward -n wxd service/ibm-lh-minio-svc 9001:9001 --address 0.0.0.0 > /dev/null 2>&1 &
   
   # MDS (Metadata Service)
   nohup kubectl port-forward -n wxd service/ibm-lh-mds-thrift-svc 8381:8381 --address 0.0.0.0 > /dev/null 2>&1 &
   ```

   > 📖 **Reference**: See the [IBM watsonx.data documentation](https://www.ibm.com/docs/en/watsonxdata/standard/2.3.x?topic=administering-exposing-minio-service) for more information.

   Access MinIO at [http://localhost:9001/](http://localhost:9001/) with credentials:
   - **Username**: `dummyvalue`
   - **Password**: `dummyvalue`

   <div align="center">
   
   ![minio-homepage](./assets/minio-homepage.png)
   
   </div>

### C. DataStax Hyper-Converged Database
In case you have access to HCD please install according to the [instructions here](./hcd-install.md). Otherwise substitute HCD with **Apache Cassandra 5** in Docker. It does not provide HCD enterprise features but is enough to exercise watsonx.data against Cassandra.

1. **🐳 Run Cassandra 5 in Docker**

   From the repository root (so `sample-data.cql` is on the host path used below):

   ```bash
   docker run -d --name wxd-cassandra \
     -p 9042:9042 \
     -v "$(pwd)/sample-data.cql:/schema/sample-data.cql:ro" \
     cassandra:5.0
   ```

   Wait until the node listens (first boot can take a minute or two):

   ```bash
   docker logs -f wxd-cassandra
   ```

   > ✅ **Success indicator**: logs contain a Cassandra startup completion line such as `Startup complete`.

   Press `Ctrl+C` to stop following logs; the container keeps running.

2. **🔍 Test `cqlsh` inside the container**

   ```bash
   docker exec -it wxd-cassandra cqlsh -u cassandra -p cassandra
   ```

   Type `quit` to exit the CQL shell.

3. **📊 Load sample data**

   ```bash
   docker exec -i wxd-cassandra cqlsh -u cassandra -p cassandra -f /schema/sample-data.cql
   ```

4. **🧹 Stop or remove the container (when finished)**

   ```bash
   docker stop wxd-cassandra
   docker rm wxd-cassandra
   ```

> 🎉 **Success!** Cassandra is listening on **localhost:9042** and the sample schema/data are loaded. Use the connection values in the next section when you register the catalog in watsonx.data (from the cluster, `host.containers.internal` and port **9042** as in the table below).

### C. Add HCD (or Cassandra) to watsonx.data

1. **🔗 Connect HCD to watsonx.data**
   - Navigate to [https://localhost:6443/#/infrastructure-manager](https://localhost:6443/#/infrastructure-manager)
   - Click `Add component`
   - Select `Cassandra` as a data source
   - Click `Next`

2. **⚙️ Configuration Details**  
   Use the following configuration details:

   | Field | Value |
   |-------|-------|
   | **Display name** | `HCD` |
   | **Hostname** | Use your machine’s public IP address (find with `curl ifconfig.me` or `hostname -I | awk '{print $1}'`) |
   | **Port** | `9042` |
   | **Username** | `cassandra` |
   | **Password** | `cassandra` |

   Now first click `Test connection`. Then continue configuration:

   | Field | Value |
   |-------|-------|
   | **Associate catalog** | ✅ Checked |
   | **Catalog name** | `hcd` |

   Click `Create`.

3. **🔗 Associate the HCD Catalog with Presto**
   - Within the watsonx.data UI, once your HCD (Cassandra) catalog has been created, you need to associate it with the Presto query engine to enable SQL querying on Cassandra data.
   - Navigate to the Infrastructure Manager by clicking the "Infrastructure Manager" section.
   - Hover over the `hcd` catalog and click on `Manage associations`.
   - Locate your newly created `hcd` catalog and add it to Presto.
   - Select the `presto-01` engine and click `Save and restart Engine`.
   - Once the association is complete and Presto has restarted, your Cassandra data is available as SQL tables in Presto.

4. **✅ Verify Data Access**
   - Navigate to `Data Manager`.
   - Expand the `hcd` catalog and the `sample_ks` keyspace.
   - Click the `users` table.
   - Click `Data sample` and confirm the 3 users are present

   <div align="center">
   
   ![wxd-data-manager](./assets/wxd-data-manager.png)
   
   </div>

> 🎉 **Success!** You have successfully configured watsonx.data to access HCD!

---

## 🔍 Federated Analytics

> 🎯 **Goal**: Query operational Cassandra data directly using SQL through Presto query engine

The first converged data integration leverages **federated analytics** using Presto as the query engine, allowing you to query Cassandra data using standard SQL without data movement.

### 📋 Steps

1. **🔍 Query Operational Data**
   - Open `Query workspace` from the left sidebar
   - Run the following query, while ensuring `Presto` is selected as the active engine:
   ```sql
   SELECT * FROM hcd.sample_ks.users;
   ```

   <div align="center">
   
   ![wxd-query-workspace](./assets/wxd-query-workspace.png)
   
   </div>

> 🎉 **Success!** You have successfully queried Cassandra data using SQL through the Presto Query Engine!

---

## 📊 Materialized Analytics using wx.d CTAS

> 🎯 **Goal**: Create materialized views for better performance and reduced operational system load

Federated analytics can be stressful on operational systems handling massive workloads with low latency requirements. **Data Offloading** addresses this by materializing data into a governed catalog with associated Parquet files. Watsonx.data facilitates this process through `CREATE TABLE AS SELECT`.

### 💡 Benefits of Data Offloading
- 🚀 **Reduced Operational Load** - Minimizes impact on production Cassandra clusters
- 💰 **Cost Optimization** - Offload workloads from expensive data warehouses
- ⚡ **Better Performance** - Faster queries on materialized data
- 🔄 **Flexible Analytics** - Combine offloaded data with warehouse data

### 📋 Implementation Steps

1. **🗂️ Create Iceberg Schema**
   - Click `Data manager` → `Create` → `Create schema`
   - Select:
     - **Catalog**: `iceberg_data`
     - **Name**: `hcd_users`
   - Click `Create`

2. **📦 Transfer Data with CTAS**
   - Click `Query workspace` → `+` (new query tab)
   - Execute the following CTAS (Create Table As Select) query:
   ```sql
   CREATE TABLE iceberg_data.hcd_users.users AS
   SELECT * FROM hcd.sample_ks.users;
   ```

   <div align="center">
   
   ![wxd-query-manager-ctas](./assets/wxd-query-workspace-ctas.png)
   
   </div>

3. **✅ Verify Materialized Data**
   - Click `Query workspace` → `+` (new query tab)
   - Run the following query on the analytical catalog:
   ```sql
   SELECT * FROM iceberg_data.hcd_users.users;
   ```

   <div align="center">
   
   ![wxd-query-manager-iceberg](./assets/wxd-query-workspace-iceberg.png)
   
   </div>

> 🎉 **Success!** You have successfully queried the newly created catalog, offloading query workload from the operational HCD database!

---

## ⚡ Utilizing the Spark Engine for Materialized Analytics

> 🎯 **Goal**: Leverage Apache Spark for advanced data processing and analytics workloads

Many DataStax DSE customers require Spark capabilities for operational data analytics. With watsonx.data, you can achieve seamless synergy between operational and analytical processing using the Hyper-Converged Database (HCD).

This section uses the [cass_spark_iceberg repository](https://github.ibm.com/pravin-bhat/cass_spark_iceberg) that:
1. Pulls the operational data from HCD
2. Turns it into analytical data using a Star-schema and stores in Iceberg tables
3. Runs several analytical queries on the Iceberg tables, offloading workload from HCD

<div align="center">

![star-schema](./assets/star-schema.png)

</div>

💡 For more information about the process, sequence, tables and see [OLAP-STAR-SCHEMA.md](./OLAP-STAR-SCHEMA.md).

### 📋 Implementation Steps

1. **🔧 Create Spark Engine**
   - Click `Infrastructure manager` and click 'Add component`
   - Select `IBM Spark` → `Next`
   - Configure:
     - **Display name**: `spark-01`
     - **Associated catalogs**: `iceberg_data`
   - Click `Create`

2. **📥 Clone and Build Sample Application**  
   This step depends on the contactpoint for Cassandra to be set correctly in `.../utils/CassUtil.java` on line 17.

   In order to find your configured datacenter name, check the Cassandra config or run:

   **Standalone HCD binary:**

   ```bash
   ./hcd-1.2.3/bin/nodetool status | grep Datacenter
   ```
   **Using Docker Cassandra:**

   ```bash
   docker exec -it wxd-cassandra nodetool status | grep Datacenter
   ```
   
   First clone the app:
   ```bash
   # Clone the example repository
   git clone git@github.ibm.com:pravin-bhat/cass_spark_iceberg.git
   cd cass_spark_iceberg
   ```

   Then (optionally if required) update the `DATACENTER` value in `cass_spark_iceberg/src/main/java/com/ibm/wxd/datalabs/demo/cass_spark_iceberg/utils/CassUtil.java`.

   Now build the app
   ```
   # Update Cassandra connection settings in CassUtil.java
   # Build the application
   mvn clean package
   ```

3. **📊 Generate Sample Data**

   This steps utilized the 
   ```bash
   mvn exec:java -Dexec.mainClass="com.ibm.wxd.datalabs.demo.cass_spark_iceberg.LoadCustomerOrdersById"
   ```

   🔍 **Verify Data**: Check data creation in watsonx.data Query workspace or via CQL.

   **Standalone HCD binary:**

   ```bash
   ./hcd-1.2.3/bin/cqlsh
   ```
   **Using Docker Cassandra:**

   ```bash
   docker exec -it wxd-cassandra cqlsh -u cassandra -p cassandra
   ```

   Then run the following query:

   ```sql
   SELECT * FROM retail_ks.customer_orders_by_id;
   ```

4. **🪣 Prepare MinIO S3 Buckets**
   - Ensure MinIO service is port-forwarded (see [Section B](#b-ibm-watsonxdata-developer-edition))
   - Navigate to http://localhost:9001/login and login with `dummyvalue` / `dummyvalue`.
   - Create buckets: `olap` and `spark-artifacts`
   - Upload JAR file: `cass-spark-iceberg-1.7.jar` → `spark-artifacts` bucket

5. **📊 Monitor Execution**
   - Execute logs watcher from the root of the repo: `../spark-logs.sh`
   - Kick off the next step and watch results in the logs watcher terminal 🎉

6. **🚀 Run OLAP Job**
   - Navigate to `wx.d Infrastructure manager` → Click `Spark` engine
   - Click `Applications` → `Create application +`
   - Click `Payload` and paste the configuration while ensuring to replace `spark.cassandra.connection.host` with your machine's IP address:

   ```json
   {
       "application_details": {
           "application": "s3a://spark-artifacts/cass-spark-iceberg-1.7.jar",
           "class": "com.ibm.wxd.datalabs.demo.cass_spark_iceberg.CassandraToIceberg",
           "conf": {
               "spark.cassandra.connection.host": "<YOUR-IP-HERE>>",
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

   Now click `Submit application` and watch the logging window for output.

---

## 📚 References

| Resource | Description | Link |
|----------|-------------|------|
| **IBM watsonx.data Documentation** | Official installation guide | [Developer Edition Setup](https://www.ibm.com/docs/en/watsonxdata/standard/2.3.x?topic=developer-edition-new-version) |
| **DataStax HCD Integration** | GitHub repository with integration examples | [wx.d-developers-edition-add-hcd](https://github.ibm.com/Data-Labs/wx.d-developers-edition-add-hcd) |
| **Spark Iceberg Example** | Sample application by Pravin Bhat | [cass_spark_iceberg](https://github.ibm.com/pravin-bhat/cass_spark_iceberg) |

---

<div align="center">

*For additional support, please refer to the official documentation or contact your IBM representative.*

</div>

/v2