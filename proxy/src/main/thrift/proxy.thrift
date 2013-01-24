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
namespace java org.apache.accumulo.proxy.thrift

struct Key {
	1:binary row;
	2:binary colFamily;
	3:binary colQualifier;
	4:binary colVisibility;
	5:optional i64 timestamp
}

enum PartialKey {
  ROW,
  ROW_COLFAM,
  ROW_COLFAM_COLQUAL,
  ROW_COLFAM_COLQUAL_COLVIS,
  ROW_COLFAM_COLQUAL_COLVIS_TIME,
  ROW_COLFAM_COLQUAL_COLVIS_TIME_DEL
}

struct ColumnUpdate {
	1:binary colFamily;
	2:binary colQualifier;
	3:optional binary colVisibility;
	4:optional i64 timestamp;
	5:optional binary value;
	6:optional bool deleteCell;
}

struct KeyValue {
	1:Key key,
	2:binary value
}

struct ScanResult {
	1:list<KeyValue> results,
	2:bool more
}

struct Range {
        1:Key start,
	2:bool startInclusive
        3:Key stop,
	4:bool stopInclusive
}

struct UserPass
{
  1:string username;
  2:binary password;
}

struct IteratorSetting {
  1: i32 priority;
  2: string name;
  3: string iteratorClass;
  4: map<string,string> properties;
}

struct KeyValueAndPeek{
    1:KeyValue keyValue;
    2:bool hasNext;
}

enum TablePermission {
  READ = 2,
  WRITE = 3,
  BULK_IMPORT = 4,
  ALTER_TABLE = 5,
  GRANT = 6,
  DROP_TABLE = 7,
}

enum SystemPermission {
  GRANT = 0,
  CREATE_TABLE = 1,
  DROP_TABLE = 2,
  ALTER_TABLE = 3,
  CREATE_USER = 4,
  DROP_USER = 5,
  ALTER_USER = 6,
  SYSTEM = 7,
}

enum ScanType {
    SINGLE,
    BATCH
}

enum ScanState {
    IDLE,
    RUNNING,
    QUEUED
}

struct KeyExtent {
  1:string tableId,
  2:binary endRow,
  3:binary prevEndRow
}

struct Column {
  1:binary colFamily;
  2:binary colQualifier;
  3:binary colVisibility;
}

struct ActiveScan {
    1:string client
    2:string user
    3:string table
    4:i64 age
    5:i64 idleTime
    6:ScanType type
    7:ScanState state
    8:KeyExtent extent
    9:list<Column> columns
    10:list<IteratorSetting> iterators
    11:list<binary> authorizations
}

enum CompactionType {
   MINOR,
   MERGE,
   MAJOR,
   FULL
}

enum CompactionReason {
   USER,
   SYSTEM,
   CHOP,
   IDLE,
   CLOSE
}

struct ActiveCompaction {
    1:KeyExtent extent
    2:i64 age
    3:list<string> inputFiles
    4:string outputFile
    5:CompactionType type
    6:CompactionReason reason
    7:string localityGroup
    8:i64 entriesRead
    9:i64 entriesWritten
    10:list<IteratorSetting> iterators;
}

enum IteratorScope {
  MINC,
  MAJC,
  SCAN
}

enum TimeType {
  LOGICAL,
  MILLIS
}

exception UnknownScanner
{
 1:string msg;
}

exception UnknownWriter
{
 1:string msg;
}

exception NoMoreEntriesException
{
 1:string msg;
}

exception AccumuloException
{
  1:string msg;
}
exception AccumuloSecurityException
{
  1:string msg;
}
exception TableNotFoundException
{
  1:string msg;
}

exception TableExistsException
{
  1:string msg;
}

service AccumuloProxy
{
  bool ping (1:UserPass userpass);

  // table operations
  i32 addConstraint (1:UserPass userpass, 2:string tableName, 3:string constraintClassName) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2, 3:TableNotFoundException ouch3);
  void addSplits (1:UserPass userpass, 2:string tableName, 3:set<binary> splits) throws (1:TableNotFoundException ouch1, 2:AccumuloException ouch2, 3:AccumuloSecurityException ouch3);
  void attachIterator (1:UserPass userpass, 2:string tableName, 3:IteratorSetting setting, 4:set<IteratorScope> scopes) throws (1:AccumuloSecurityException ouch1, 2:AccumuloException ouch2, 3:TableNotFoundException ouch3);
  void checkIteratorConflicts (1:UserPass userpass, 2:string tableName, 3:IteratorSetting setting, 4:set<IteratorScope> scopes) throws (1:AccumuloException ouch1, 2:TableNotFoundException ouch2);
  void clearLocatorCache (1:UserPass userpass, 2:string tableName) throws (1:TableNotFoundException ouch1);
  void cloneTable (1:UserPass userpass, 2:string tableName, 3:string newTableName, 4:bool flush, 5:map<string,string> propertiesToSet, 6:set<string> propertiesToExclude) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2, 3:TableNotFoundException ouch3, 4:TableExistsException ouch4);
  void compactTable (1:UserPass userpass, 2:string tableName, 3:binary startRow, 4:binary endRow, 5:list<IteratorSetting> iterators, 6:bool flush, 7:bool wait) throws (1:AccumuloSecurityException ouch1, 2:TableNotFoundException ouch2, 3:AccumuloException ouch3);
  void createTable (1:UserPass userpass, 2:string tableName, 3:bool versioningIter, 4:TimeType type) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2, 3:TableExistsException ouch3);
  void deleteTable (1:UserPass userpass, 2:string tableName) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2, 3:TableNotFoundException ouch3);
  void deleteRows (1:UserPass userpass, 2:string tableName, 3:binary startRow, 4:binary endRow) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2, 3:TableNotFoundException ouch3);
  void exportTable (1:UserPass userpass, 2:string tableName, 3:string exportDir) throws (1:TableNotFoundException ouch1, 2:AccumuloException ouch2, 3:AccumuloSecurityException ouch3);
  void flushTable (1:UserPass userpass, 2:string tableName, 3:binary startRow, 4:binary endRow, 5:bool wait) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  map<string,set<string>> getLocalityGroups (1:UserPass userpass, 2:string tableName) throws (1:AccumuloException ouch1, 2:TableNotFoundException ouch2);
  IteratorSetting getIteratorSetting (1:UserPass userpass, 2:string tableName, 3:string iteratorName, 4:IteratorScope scope) throws (1:AccumuloSecurityException ouch1, 2:AccumuloException ouch2, 3:TableNotFoundException ouch3);
  binary getMaxRow (1:UserPass userpass, 2:string tableName, 3:list<binary> auths, 4:binary startRow, 5:bool startInclusive, 6:binary endRow, 7:bool endInclusive) throws (1:TableNotFoundException ouch1, 2:AccumuloException ouch2, 3:AccumuloSecurityException ouch3);
  map<string,string> getTableProperties (1:UserPass userpass, 2:string tableName) throws (1:AccumuloException ouch1, 2:TableNotFoundException ouch2);
  list<binary> getSplits (1:UserPass userpass, 2:string tableName, 3:i32 maxSplits) throws (1:TableNotFoundException ouch1);
  void importDirectory (1:UserPass userpass, 2:string tableName, 3:string importDir, 4:string failureDir, 5:bool setTime) throws (1:TableNotFoundException ouch1, 2:AccumuloException ouch3, 3:AccumuloSecurityException ouch4);
  void importTable (1:UserPass userpass, 2:string tableName, 3:string importDir) throws (1:TableExistsException ouch1, 2:AccumuloException ouch2, 3:AccumuloSecurityException ouch3);
  set<string> listTables (1:UserPass userpass);
  map<string,set<IteratorScope>> listIterators (1:UserPass userpass, 2:string tableName) throws (1:AccumuloSecurityException ouch1, 2:AccumuloException ouch2, 3:TableNotFoundException ouch3);
  map<string,i32> listConstraints (1:UserPass userpass, 2:string tableName) throws (1:AccumuloException ouch1, 2:TableNotFoundException ouch2);
  void mergeTablets (1:UserPass userpass, 2:string tableName, 3:binary startRow, 4:binary endRow) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2, 3:TableNotFoundException ouch3);
  void offlineTable (1:UserPass userpass, 2:string tableName) throws (1:AccumuloSecurityException ouch1, 2:AccumuloException ouch2, 3:TableNotFoundException ouch3);
  void onlineTable (1:UserPass userpass, 2:string tableName) throws (1:AccumuloSecurityException ouch1, 2:AccumuloException ouch2, 3:TableNotFoundException ouch3);
  void removeConstraint (1:UserPass userpass, 2:string tableName, 3:i32 constraint) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  void removeIterator (1:UserPass userpass, 2:string tableName, 3:string iterName, 4:set<IteratorScope> scopes) throws (1:AccumuloSecurityException ouch1, 2:AccumuloException ouch2, 3:TableNotFoundException ouch3);
  void removeTableProperty (1:UserPass userpass, 2:string tableName, 3:string property) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  void renameTable (1:UserPass userpass, 2:string oldTableName, 3:string newTableName) throws (1:AccumuloSecurityException ouch1, 2:TableNotFoundException ouch2, 3:AccumuloException ouch3, 4:TableExistsException ouch4);
  void setLocalityGroups (1:UserPass userpass, 2:string tableName, 3:map<string,set<string>> groups) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2, 3:TableNotFoundException ouch3);
  void setTableProperty (1:UserPass userpass, 2:string tableName, 3:string property, 4:string value) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  set<Range> splitRangeByTablets (1:UserPass userpass, 2:string tableName, 3:Range range, 4:i32 maxSplits) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2, 3:TableNotFoundException ouch3);
  bool tableExists (1:UserPass userpass, 2:string tableName);
  map<string,string> tableIdMap (1:UserPass userpass);

  // instance operations
  void pingTabletServer(1:UserPass userpass, 2:string tserver) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  list<ActiveScan> getActiveScans (1:UserPass userpass, 2:string tserver) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  list<ActiveCompaction> getActiveCompactions(1:UserPass userpass, 2:string tserver) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  map<string,string> getSiteConfiguration (1:UserPass userpass) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  map<string,string> getSystemConfiguration (1:UserPass userpass) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  list<string> getTabletServers (1:UserPass userpass);
  void removeProperty (1:UserPass userpass, 2:string property) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  void setProperty (1:UserPass userpass, 2:string property, 3:string value) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  bool testClassLoad (1:UserPass userpass, 2:string className, 3:string asTypeName) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);

  // security operations
  bool authenticateUser (1:UserPass userpass, 2:string user, 3:binary password) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  void changeUserAuthorizations (1:UserPass userpass, 2:string user, 3:set<binary> authorizations) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  void changeUserPassword (1:UserPass userpass, 2:string user, 3:binary password) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  void createUser (1:UserPass userpass, 2:string user, 3:binary password) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  void dropUser (1:UserPass userpass, 2:string user) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  list<binary> getUserAuthorizations (1:UserPass userpass, 2:string user) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  void grantSystemPermission (1:UserPass userpass, 2:string user, 3:SystemPermission perm) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  void grantTablePermission (1:UserPass userpass, 2:string user, 3:string table, 4:TablePermission perm) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  bool hasSystemPermission (1:UserPass userpass, 2:string user, 3:SystemPermission perm) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  bool hasTablePermission (1:UserPass userpass, 2:string user, 3:string table, 4:TablePermission perm) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  set<string> listUsers (1:UserPass userpass) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  void revokeSystemPermission (1:UserPass userpass, 2:string user, 3:SystemPermission perm) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);
  void revokeTablePermission (1:UserPass userpass, 2:string user, 3:string table, 4:TablePermission perm) throws (1:AccumuloException ouch1, 2:AccumuloSecurityException ouch2);


  // scanning
  string createBatchScanner(1:UserPass userpass, 2:string tableName, 3:set<binary> authorizations, 4:list<IteratorSetting> iteratorSetting, 5:list<Range> range);
  string createScanner(1:UserPass userpass, 2:string tableName, 3:set<binary> authorizations, 4:list<IteratorSetting> iteratorSetting, 5:Range range);

  // use the scanner
  bool scanner_hasnext(1:string scanner) throws (1:UnknownScanner ouch1);
  KeyValueAndPeek scanner_next(1:string scanner) throws(1:NoMoreEntriesException ouch1, 2:UnknownScanner ouch2, 3:AccumuloSecurityException ouch3);
  ScanResult scanner_next_k(1:string scanner, 2:i32 k) throws(1:NoMoreEntriesException ouch1, 2:UnknownScanner ouch2, 3:AccumuloSecurityException ouch3);
  void close_scanner(1:string scanner) throws (1:UnknownScanner ouch1);

  // writing
  void updateAndFlush(1:UserPass userpass, 2:string tableName, 3:map<binary, list<ColumnUpdate>> cells);
  string createWriter(1:UserPass userpass, 2:string tableName);

  // use the writer
  oneway void writer_update(1:string writer, 2:map<binary, list<ColumnUpdate>> cells);
  void writer_flush(1:string writer) throws (1:UnknownWriter ouch1, 2:AccumuloSecurityException ouch2);
  void writer_close(1:string writer) throws (1:UnknownWriter ouch1, 2:AccumuloSecurityException ouch2);

  // utilities
  Range getRowRange(1:binary row);
  Key getFollowing(1:Key key, 2:PartialKey part);
}