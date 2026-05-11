# DataStax Hyper-Converged Database
This step requires to have access to the HCD repository which is available through product management. In case you don't have this, please proceed with the latest Cassandra release.

1. **📥 Download & Extract**
   ```bash
   # Download the HCD tarball
   wget http://downloads.datastax.com/hcd/hcd-1.2.3-bin.tar.gz
   
   # Extract the archive
   tar -xzf hcd-1.2.3-bin.tar.gz
   ```

2. **Create the logging directory**
   ```bash
   sudo mkdir /var/log/cassandra
   sudo chown $(whoami):$(id -gn) /var/log/cassandra
   ```

3. **☕ Configure Java Environment**
   ```bash
   # Set Java 17 environment (required for HCD)
   export JAVA_HOME="$(/usr/libexec/java_home -v17)"
   export PATH="$JAVA_HOME/bin:$PATH"
   export CASSANDRA_JDK_UNSUPPORTED=true
   ```

4. **🚀 Start HCD**
   ```bash
   ./hcd-1.2.3/bin/hcd cassandra
   ```

   > ✅ **Success Indicator**: Look for this message in the logs:
   > ```
   > INFO  [main] 2025-10-27 13:40:24,500 HcdDaemon.java:22 - HCD startup complete
   > ```

5. **🔍 Test Connection**
   ```bash
   ./hcd-1.2.3/bin/cqlsh -u cassandra -p cassandra
   ```
   ⚠️ This step depends on Python to be installed.
   
   Type `quit` to exit the CQL shell.