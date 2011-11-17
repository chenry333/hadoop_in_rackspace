export HADOOP_HOME=/usr/lib/hadoop
export HADOOP_LOG_DIR=${HADOOP_HOME}/logs
export PATH=$PATH:$HADOOP_HOME/bin
export HADOOP_CLASSPATH="/usr/lib/hadoop/lib/hadoop-lzo-0.4.13.jar:$HADOOP_CLASSPATH"
export PIG_CLASSPATH="/usr/lib/hadoop/lib/hadoop-lzo-0.4.13.jar:$PIG_CLASSPATH"
export LD_LIBRARY_PATH=/usr/local/lib
