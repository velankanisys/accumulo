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
package org.apache.accumulo.test.randomwalk.security;

import java.util.Properties;

import org.apache.accumulo.core.client.AccumuloException;
import org.apache.accumulo.core.client.AccumuloSecurityException;
import org.apache.accumulo.core.client.Connector;
import org.apache.accumulo.core.security.tokens.PasswordToken;
import org.apache.accumulo.core.security.tokens.SecurityToken;
import org.apache.accumulo.test.randomwalk.State;
import org.apache.accumulo.test.randomwalk.Test;

public class CreateUser extends Test {
  
  @Override
  public void visit(State state, Properties props) throws Exception {
    Connector conn = state.getInstance().getConnector(WalkingSecurity.get(state).getSysCredentials());
    
    String tableUserName = WalkingSecurity.get(state).getTabUserName();
    
    boolean exists = WalkingSecurity.get(state).userExists(tableUserName);
    boolean hasPermission = WalkingSecurity.get(state).canCreateUser(WalkingSecurity.get(state).getSysCredentials(), tableUserName);
    SecurityToken tabUserPass = new PasswordToken().setPassword("Super Sekret Table User Password".getBytes());
    try {
      conn.securityOperations().createUser(tableUserName, tabUserPass);
    } catch (AccumuloSecurityException ae) {
      switch (ae.getErrorCode()) {
        case PERMISSION_DENIED:
          if (hasPermission)
            throw new AccumuloException("Got a security exception when I should have had permission.", ae);
          else
          // create user anyway for sake of state
          {
            if (!exists) {
              state.getConnector().securityOperations().createUser(tableUserName, tabUserPass);
              WalkingSecurity.get(state).createUser(tableUserName, tabUserPass);
            }
            return;
          }
        case USER_EXISTS:
          if (!exists)
            throw new AccumuloException("Got security exception when the user shouldn't have existed", ae);
          else
            return;
        default:
          throw new AccumuloException("Got unexpected exception", ae);
      }
    }
    WalkingSecurity.get(state).createUser(tableUserName, tabUserPass);
    if (!hasPermission)
      throw new AccumuloException("Didn't get Security Exception when we should have");
  }
}
