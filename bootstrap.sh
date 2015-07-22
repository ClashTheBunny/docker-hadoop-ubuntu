#!/bin/bash

: ${HADOOP_PREFIX:=/usr/local/hadoop}

source $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

rm /tmp/*.pid

# installing libraries if any - (resource urls added comma separated to the ACP system variable)
cd $HADOOP_PREFIX/share/hadoop/common ; for cp in ${ACP//,/ }; do  echo == $cp; curl -LO $cp ; done; cd -

IP_ADDRESS=$(grep $HOSTNAME /etc/hosts | awk '{print $1}')

# altering the core-site configuration
sed -i -e s/HOSTNAME/${MASTER_PORT_50070_TCP_ADDR-$IP_ADDRESS}/ /usr/local/hadoop/etc/hadoop/core-site.xml
sed -i -e s/HOSTNAME/${MASTER_PORT_50070_TCP_ADDR-$IP_ADDRESS}/ /usr/local/hadoop/etc/hadoop/yarn-site.xml
sed -i -e s/NUMBEROFNODES/${NUMBEROFNODES-2}/ /usr/local/hadoop/etc/hadoop/hdfs-site.xml

sed -i -e 's/mapreduce_map_memory_mb/640/g' \
  -e 's/mapreduce_map_java_opts/-Xmx512m/g' \
  -e 's/mapreduce_reduce_memory_mb/1280/g' \
  -e 's/mapreduce_reduce_java_opts/-Xmx1024m/g' \
  -e 's/mapreduce_task_io_sort_mb/256/g' /usr/local/hadoop/etc/hadoop/mapred-site.xml
sed -i -e 's/yarn_scheduler_minimum_allocation_mb/640/g' \
  -e 's/yarn_scheduler_maximum_allocation_mb/1920/g' \
  -e 's/yarn_nodemanager_resource_memory_mb/1920/g' \
  -e 's/yarn_app_mapreduce_am_resource_mb/640/g' \
  -e 's/yarn_app_mapreduce_am_command_opts/-Xmx512m/g' /usr/local/hadoop/etc/hadoop/yarn-site.xml

while true; do
        case $1 in
                ssh)
                  service ssh start
                ;;
                rm)
                    $HADOOP_PREFIX/sbin/yarn-daemon.sh          --config $HADOOP_CONF_DIR start resourcemanager
                ;;
                nm)
                    $HADOOP_PREFIX/sbin/yarn-daemon.sh          --config $HADOOP_CONF_DIR start nodemanager
                ;;
                hs)
                    $HADOOP_PREFIX/sbin/mr-jobhistory-daemon.sh --config $HADOOP_CONF_DIR start historyserver
                ;;
                nn)
                    $HADOOP_PREFIX/sbin/hadoop-daemon.sh        --config $HADOOP_CONF_DIR start namenode
                ;;
                snn)
                    $HADOOP_PREFIX/sbin/hadoop-daemon.sh        --config $HADOOP_CONF_DIR start secondarynamenode
                ;;
                dn)
                    $HADOOP_PREFIX/sbin/hadoop-daemon.sh        --config $HADOOP_CONF_DIR start datanode
                ;;
                -d)
                  while true; do sleep 1000; done
                  break
                ;;
                -bash)
                  /bin/bash
                  break
                ;;
        esac
        shift || break
done
