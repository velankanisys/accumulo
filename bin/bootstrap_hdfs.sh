#! /usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


bin=`dirname "$0"`
bin=`cd "$bin"; pwd`

. "$bin"/config.sh

#
# Find the system context directory in HDFS
#
SYSTEM_CONTEXT_HDFS_DIR=`grep -A1 "general.vfs.classpaths" "$ACCUMULO_HOME/conf/accumulo-site.xml" | tail -1 | perl -pe 's/\s+<value>//; s/<\/value>//; print $ARGV[1]'`

if [ -z "$SYSTEM_CONTEXT_HDFS_DIR" ]; then

  echo "Your accumulo-site.xml file is not set up for the HDFS Classloader. Please add the following to your accumulo-site.xml file:"
  echo ""
  echo "<property>"
  echo "   <name>general.vfs.classpaths</name>"
  echo "   <value>hdfs://host:port/dir</value>"
  echo "   <description>location of the jars for the default (system) context</description>"
  echo "</property>"
  exit
fi

#
# Create the system context directy in HDFS if it does not exist
#
"$HADOOP_PREFIX/bin/hadoop" fs -ls "$SYSTEM_CONTEXT_HDFS_DIR"  > /dev/null
if [ $? -ne 0 ]; then
  "$HADOOP_PREFIX/bin/hadoop" fs -mkdir "$SYSTEM_CONTEXT_HDFS_DIR"  > /dev/null
fi

#
# Replicate to all slaves to avoid network contention on startup
#
NUM_SLAVES=`wc -l $ACCUMULO_HOME/conf/slaves | grep -P '^\d+(?= )' -o`

#let each datanode service around 50 clients
let "REP=$NUM_SLAVES/50"

if [ $REP -lt 3 ]; then
  REP=3
fi

#
# Copy all jars in lib to the system context directory
#
"$HADOOP_PREFIX/bin/hadoop" fs -moveFromLocal "$ACCUMULO_HOME"/lib/*.jar "$SYSTEM_CONTEXT_HDFS_DIR"  > /dev/null

"$HADOOP_PREFIX/bin/hadoop" fs -setrep -R $REP "$SYSTEM_CONTEXT_HDFS_DIR"  > /dev/null


#
# We need two of the jars in lib, copy them back out and remove them from the system context dir
#
"$HADOOP_PREFIX/bin/hadoop" fs -copyToLocal "$SYSTEM_CONTEXT_HDFS_DIR/log4j-1.2.16.jar" "$ACCUMULO_HOME/lib/."  > /dev/null
"$HADOOP_PREFIX/bin/hadoop" fs -rmr "$SYSTEM_CONTEXT_HDFS_DIR/log4j-1.2.16.jar"  > /dev/null
"$HADOOP_PREFIX/bin/hadoop" fs -copyToLocal "$SYSTEM_CONTEXT_HDFS_DIR/commons-vfs2-2.0.jar" "$ACCUMULO_HOME/lib/."  > /dev/null
"$HADOOP_PREFIX/bin/hadoop" fs -rmr "$SYSTEM_CONTEXT_HDFS_DIR/commons-vfs2-2.0.jar"  > /dev/null
"$HADOOP_PREFIX/bin/hadoop" fs -copyToLocal "$SYSTEM_CONTEXT_HDFS_DIR/accumulo-start-${ACCUMULO_VERSION}.jar" "$ACCUMULO_HOME/lib/."  > /dev/null
"$HADOOP_PREFIX/bin/hadoop" fs -rmr "$SYSTEM_CONTEXT_HDFS_DIR/accumulo-start-${ACCUMULO_VERSION}.jar"  > /dev/null
