#!/bin/bash

: ${HADOOP_PREFIX:=/usr/local/hadoop}

source $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

rm /tmp/*.pid

# installing libraries if any - (resource urls added comma separated to the ACP system variable)
cd $HADOOP_PREFIX/share/hadoop/common ; for cp in ${ACP//,/ }; do  echo == $cp; curl -LO $cp ; done; cd -

# altering the core-site configuration
sed s/HOSTNAME/${MASTER_PORT_50070_TCP_ADDR-$HOSTNAME}/ /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml
sed s/HOSTNAME/${MASTER_PORT_50070_TCP_ADDR-$HOSTNAME}/ /usr/local/hadoop/etc/hadoop/yarn-site.xml.template > /usr/local/hadoop/etc/hadoop/yarn-site.xml
sed s/NUMBEROFNODES/${NUMBEROFNODES-2}/ /usr/local/hadoop/etc/hadoop/hdfs-site.xml.template > /usr/local/hadoop/etc/hadoop/hdfs-site.xml

while true; do
        case $1 in
                ssh)
                  service ssh start
                ;;
                dfs)
                    $HADOOP_PREFIX/sbin/start-dfs.sh;
                ;;
                yarn)
                    $HADOOP_PREFIX/sbin/start-yarn.sh
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
