    #
#   # #   Enginsight GmbH
# # # #   Geschäftsführer: Mario Jandeck, Eric Range
# #   #   Hans-Knöll-Straße 6, 07745 Jena
  #   

# PLEASE READ ME!
# You need to enable the PERFORMANCE_SCHEMA.
# See the https://dev.mysql.com/doc/refman/5.6/en/performance-schema-startup-configuration.html for details:
#
# Please add the following configuration to your mysql.cnf:
#  [mysqld] 
#  performance_schema=ON

MYSQL_USER="root"
MYSQL_PASS=""

# If you need a password, please use "-p $MYSQL_PASS" within the command.
QUERY=$(mysql -u $MYSQL_USER -e "use sys; \
  select 
  VARIABLE_NAME as query_type, 
  VARIABLE_VALUE as total_count, 
  round(VARIABLE_VALUE / 
     (select VARIABLE_VALUE 
      from sys.metrics 
      where VARIABLE_NAME = 'Uptime_since_flush_status'), 2) as per_second,
  round(VARIABLE_VALUE / 
    ((select VARIABLE_VALUE 
      from sys.metrics 
      where VARIABLE_NAME = 'Uptime_since_flush_status') / (60))) as per_minute
from 
  sys.metrics
where 
  VARIABLE_NAME IN ('Queries', 'Questions', 'Threads_connected', 'Bytes_received', 'Bytes_sent', 'Slow_queries', 'qcache_hits')";)

mysql_version=$(mysql --version)
mysql_queries=$(echo "$QUERY" | awk '{if($1=="queries") { print $3 }}')
mysql_questions=$(echo "$QUERY" | awk '{if($1=="questions") { print $3 }}')
mysql_connections=$(echo "$QUERY" | awk '{if($1=="threads_connected") { print $2 }}')
mysql_bytes_sent=$(echo "$QUERY" | awk '{if($1=="bytes_sent") { print $3 }}')
mysql_bytes_received=$(echo "$QUERY" | awk '{if($1=="bytes_received") { print $3 }}')
mysql_slow_queries=$(echo "$QUERY" | awk '{if($1=="slow_queries") { print $3 }}')
mysql_cache_hits=$(echo "$QUERY" | awk '{if($1=="qcache_hits") { print $3 }}')
mysql_cache_misses=$(echo "$QUERY" | awk '{if($1=="qcache_not_cached") { print $3 }}')

cat << EOF
__METRICS__={
  "mysql_queries_per_second": ${mysql_queries:-0},
  "mysql_questions_per_second": ${mysql_questions:-0},
  "mysql_connections": ${mysql_connections:-0},
  "mysql_bytes_sent_per_second": ${mysql_bytes_sent:-0},
  "mysql_bytes_received_per_second": ${mysql_bytes_received:-0},
  "mysql_slow_queries_per_second": ${mysql_slow_queries:-0},
  "mysql_cache_hits_per_second": ${mysql_cache_hits:-0},
  "mysql_cache_misses_per_second": ${mysql_cache_misses:-0}
}
EOF
