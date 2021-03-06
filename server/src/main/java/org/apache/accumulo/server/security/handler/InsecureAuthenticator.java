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
package org.apache.accumulo.server.security.handler;

import java.util.Collections;
import java.util.Set;

import org.apache.accumulo.core.client.AccumuloSecurityException;
import org.apache.accumulo.core.security.thrift.Credential;
import org.apache.accumulo.core.security.tokens.NullToken;
import org.apache.accumulo.core.security.tokens.SecurityToken;

/**
 * This is an Authenticator implementation that doesn't actually do any security. Use at your own risk.
 */
public class InsecureAuthenticator extends org.apache.accumulo.core.security.handler.InsecureAuthenticator implements Authenticator {
  
  @Override
  public void initialize(String instanceId, boolean initialize) {
    return;
  }
  
  @Override
  public boolean validSecurityHandlers(Authorizor auth, PermissionHandler pm) {
    return true;
  }
  
  @Override
  public void initializeSecurity(Credential credentials, String principal, byte[] token) throws AccumuloSecurityException {
    return;
  }
  
  @Override
  public boolean authenticateUser(String principal, SecurityToken token) {
    return true;
  }
  
  @Override
  public Set<String> listUsers() throws AccumuloSecurityException {
    return Collections.emptySet();
  }
  
  @Override
  public void createUser(String principal, SecurityToken token) throws AccumuloSecurityException {
    return;
  }
  
  @Override
  public void dropUser(String user) throws AccumuloSecurityException {
    return;
  }
  
  @Override
  public void changePassword(String user, SecurityToken token) throws AccumuloSecurityException {
    return;
  }

  @Override
  public boolean userExists(String user) {
    return true;
  }

  @Override
  public String getTokenLoginClass() {
    return null;
  }

  @Override
  public boolean validTokenClass(String tokenClass) {
    return tokenClass.equals(NullToken.class.getCanonicalName());
  }
  
}
