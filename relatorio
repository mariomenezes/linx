#Only print logs from access
#
awk '{print $9,$7}' /var/log/nginx/access.log | sort | uniq -c | sort -rn
