/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package org.apache.accumulo.server.client;

import java.nio.ByteBuffer;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.concurrent.Callable;

import org.apache.accumulo.core.Constants;
import org.apache.accumulo.core.client.AccumuloSecurityException;
import org.apache.accumulo.core.client.Instance;
import org.apache.accumulo.core.client.impl.Tables;
import org.apache.accumulo.core.client.impl.thrift.ClientService;
import org.apache.accumulo.core.client.impl.thrift.ConfigurationType;
import org.apache.accumulo.core.client.impl.thrift.TableOperation;
import org.apache.accumulo.core.client.impl.thrift.TableOperationExceptionType;
import org.apache.accumulo.core.client.impl.thrift.ThriftTableOperationException;
import org.apache.accumulo.core.conf.AccumuloConfiguration;
import org.apache.accumulo.core.conf.Property;
import org.apache.accumulo.core.security.Authorizations;
import org.apache.accumulo.core.security.SystemPermission;
import org.apache.accumulo.core.security.TablePermission;
import org.apache.accumulo.core.security.thrift.Credential;
import org.apache.accumulo.core.security.thrift.SecurityErrorCode;
import org.apache.accumulo.core.security.thrift.ThriftSecurityException;
import org.apache.accumulo.server.conf.ServerConfiguration;
import org.apache.accumulo.server.security.AuditedSecurityOperation;
import org.apache.accumulo.server.security.SecurityOperation;
import org.apache.accumulo.server.zookeeper.TransactionWatcher;
import org.apache.accumulo.start.classloader.vfs.AccumuloVFSClassLoader;
import org.apache.accumulo.trace.thrift.TInfo;
import org.apache.log4j.Logger;
import org.apache.thrift.TException;

public class ClientServiceHandler implements ClientService.Iface {
  private static final Logger log = Logger.getLogger(ClientServiceHandler.class);
  private static SecurityOperation security = AuditedSecurityOperation.getInstance();
  protected final TransactionWatcher transactionWatcher;
  private final Instance instance;
  
  public ClientServiceHandler(Instance instance, TransactionWatcher transactionWatcher) {
    this.instance = instance;
    this.transactionWatcher = transactionWatcher;
  }
  
  protected String checkTableId(String tableName, TableOperation operation) throws ThriftTableOperationException {
    String tableId = Tables.getNameToIdMap(instance).get(tableName);
    if (tableId == null) {
      // maybe the table exist, but the cache was not updated yet... so try to clear the cache and check again
      Tables.clearCache(instance);
      tableId = Tables.getNameToIdMap(instance).get(tableName);
      if (tableId == null)
        throw new ThriftTableOperationException(null, tableName, operation, TableOperationExceptionType.NOTFOUND, null);
    }
    return tableId;
  }
  
  @Override
  public String getInstanceId() {
    return instance.getInstanceID();
  }
  
  @Override
  public String getRootTabletLocation() {
    return instance.getRootTabletLocation();
  }
  
  @Override
  public String getZooKeepers() {
    return instance.getZooKeepers();
  }
  
  @Override
  public void ping(Credential credentials) {
    // anybody can call this; no authentication check
    log.info("Master reports: I just got pinged!");
  }
  
  @Override
  public boolean authenticateUser(TInfo tinfo, Credential credentials, Credential toAuth) throws ThriftSecurityException {
    try {
      return security.authenticateUser(credentials, toAuth);
    } catch (ThriftSecurityException e) {
      log.error(e);
      throw e;
    }
  }
  
  @Override
  public void changeAuthorizations(TInfo tinfo, Credential credentials, String user, List<ByteBuffer> authorizations) throws ThriftSecurityException {
    security.changeAuthorizations(credentials, user, new Authorizations(authorizations));
  }
  
  @Override
  public void changePassword(TInfo tinfo, Credential credentials, Credential toChange) throws ThriftSecurityException {
    security.changePassword(credentials, toChange);
  }
  
  @Override
  public void createUser(TInfo tinfo, Credential credentials, Credential newUser, List<ByteBuffer> authorizations)
      throws ThriftSecurityException {
    security.createUser(credentials, newUser, new Authorizations(authorizations));
  }
  
  @Override
  public void dropUser(TInfo tinfo, Credential credentials, String user) throws ThriftSecurityException {
    security.dropUser(credentials, user);
  }
  
  @Override
  public List<ByteBuffer> getUserAuthorizations(TInfo tinfo, Credential credentials, String user) throws ThriftSecurityException {
    return security.getUserAuthorizations(credentials, user).getAuthorizationsBB();
  }
  
  @Override
  public void grantSystemPermission(TInfo tinfo, Credential credentials, String user, byte permission) throws ThriftSecurityException {
    security.grantSystemPermission(credentials, user, SystemPermission.getPermissionById(permission));
  }
  
  @Override
  public void grantTablePermission(TInfo tinfo, Credential credentials, String user, String tableName, byte permission) throws ThriftSecurityException,
      ThriftTableOperationException {
    String tableId = checkTableId(tableName, TableOperation.PERMISSION);
    security.grantTablePermission(credentials, user, tableId, TablePermission.getPermissionById(permission));
  }
  
  @Override
  public void revokeSystemPermission(TInfo tinfo, Credential credentials, String user, byte permission) throws ThriftSecurityException {
    security.revokeSystemPermission(credentials, user, SystemPermission.getPermissionById(permission));
  }
  
  @Override
  public void revokeTablePermission(TInfo tinfo, Credential credentials, String user, String tableName, byte permission) throws ThriftSecurityException,
      ThriftTableOperationException {
    String tableId = checkTableId(tableName, TableOperation.PERMISSION);
    security.revokeTablePermission(credentials, user, tableId, TablePermission.getPermissionById(permission));
  }
  
  @Override
  public boolean hasSystemPermission(TInfo tinfo, Credential credentials, String user, byte sysPerm) throws ThriftSecurityException {
    return security.hasSystemPermission(credentials, user, SystemPermission.getPermissionById(sysPerm));
  }
  
  @Override
  public boolean hasTablePermission(TInfo tinfo, Credential credentials, String user, String tableName, byte tblPerm) throws ThriftSecurityException,
      ThriftTableOperationException {
    String tableId = checkTableId(tableName, TableOperation.PERMISSION);
    return security.hasTablePermission(credentials, user, tableId, TablePermission.getPermissionById(tblPerm));
  }
  
  @Override
  public Set<String> listUsers(TInfo tinfo, Credential credentials) throws ThriftSecurityException {
    return security.listUsers(credentials);
  }
  
  static private Map<String,String> conf(Credential credentials, AccumuloConfiguration conf) throws TException {
    security.authenticateUser(credentials, credentials);

    Map<String,String> result = new HashMap<String,String>();
    for (Entry<String,String> entry : conf) {
      // TODO: do we need to send any instance information?
      if (entry.getKey().equals(Property.INSTANCE_SECRET.getKey()))
        continue;
      if (entry.getKey().toLowerCase().contains("password"))
        continue;
      result.put(entry.getKey(), entry.getValue());
    }
    return result;
  }
  
  @Override
  public Map<String,String> getConfiguration(TInfo tinfo, Credential credentials, ConfigurationType type) throws TException {
    switch (type) {
      case CURRENT:
        return conf(credentials, new ServerConfiguration(instance).getConfiguration());
      case SITE:
        return conf(credentials, ServerConfiguration.getSiteConfiguration());
      case DEFAULT:
        return conf(credentials, AccumuloConfiguration.getDefaultConfiguration());
    }
    throw new RuntimeException("Unexpected configuration type " + type);
  }
  
  @Override
  public Map<String,String> getTableConfiguration(TInfo tinfo, Credential credentials, String tableName) throws TException, ThriftTableOperationException {
    String tableId = checkTableId(tableName, null);
    return conf(credentials, new ServerConfiguration(instance).getTableConfiguration(tableId));
  }
  
  @Override
  public List<String> bulkImportFiles(TInfo tinfo, final Credential tikw, final long tid, final String tableId, final List<String> files,
      final String errorDir, final boolean setTime) throws ThriftSecurityException, ThriftTableOperationException, TException {
    try {
      final Credential credentials = new Credential(tikw);
      if (!security.hasSystemPermission(credentials, credentials.getPrincipal(), SystemPermission.SYSTEM))
        throw new AccumuloSecurityException(credentials.getPrincipal(), SecurityErrorCode.PERMISSION_DENIED);
      return transactionWatcher.run(Constants.BULK_ARBITRATOR_TYPE, tid, new Callable<List<String>>() {
        @Override
        public List<String> call() throws Exception {
          return BulkImporter.bulkLoad(new ServerConfiguration(instance).getConfiguration(), instance, credentials, tid, tableId, files, errorDir, setTime);
        }
      });
    } catch (AccumuloSecurityException e) {
      throw e.asThriftException();
    } catch (Exception ex) {
      throw new TException(ex);
    }
  }
  
  @Override
  public boolean isActive(TInfo tinfo, long tid) throws TException {
    return transactionWatcher.isActive(tid);
  }
  
  @SuppressWarnings({"rawtypes", "unchecked"})
  @Override
  public boolean checkClass(TInfo tinfo, Credential credentials, String className, String interfaceMatch) throws TException {
    ClassLoader loader = getClass().getClassLoader();
    Class shouldMatch;
    try {
      shouldMatch = loader.loadClass(interfaceMatch);
      Class test = AccumuloVFSClassLoader.loadClass(className, shouldMatch);
      test.newInstance();
      return true;
    } catch (ClassCastException e) {
      log.warn("Error checking object types", e);
      return false;
    } catch (ClassNotFoundException e) {
      log.warn("Error checking object types", e);
      return false;
    } catch (InstantiationException e) {
      log.warn("Error checking object types", e);
      return false;
    } catch (IllegalAccessException e) {
      log.warn("Error checking object types", e);
      return false;
    }
  }
  
}
