source /opt/equinix/metal/bin/metal_mnmd_sharedlib.sh

logger "running /opt/equinix/metal/bin/sidekick_restart_manage.sh"

if [ -n "$LBT_GROUPS" ]; then
    rm /etc/nginx/sites-enabled/*
	for LBGROUP in $LBT_GROUPS; do
		LBGROUP_FIRST=$(echo $LBGROUP | awk -F ':' '{print$1}' | awk -F '-' '{print$1}')
		LBGROUP_LAST=$(echo $LBGROUP | awk -F ':' '{print$1}' | awk -F '-' '{print$NF}')
		LBGROUP_FIRSTNAME=$(echo $LBGROUP | awk -F ':' '{print$2}')
		LBGROUP_LASTNAME=$(echo $LBGROUP | awk -F ':' '{print$3}')
		LBGROUP_HOSTNAME=$(echo $LBGROUP | awk -F ':' '{print$4}')
		LBGROUP_PORT=$(echo $LBGROUP | awk -F ':' '{print$NF}')
		LB_NUM_IN_GROUP=$((LBGROUP_LAST-LBGROUP_FIRST+1))
		cat > /etc/nginx/sites-enabled/$LBGROUP_PORT.conf << EOL
server {
   listen       $LBGROUP_PORT;
   listen  [::]:$LBGROUP_PORT;
   server_name  $LBGROUP_HOSTNAME;

   # Allow special characters in headers
   ignore_invalid_headers off;
   # Allow any size file to be uploaded.
   # Set to a value such as 1000m; to restrict file size to a specific value
   client_max_body_size 0;
   # Disable buffering
   proxy_buffering off;
   proxy_request_buffering off;

   ssl_protocols TLSv1.2 TLSv1.3;

   location / {
      proxy_set_header Host \$http_host;
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto \$scheme;

      proxy_connect_timeout 300;
      # Default is HTTP/1, keepalive is only enabled in HTTP/1.1
      proxy_http_version 1.1;
      proxy_set_header Connection "";
      chunked_transfer_encoding off;

      proxy_pass https://object_private_$LBGROUP_PORT; # This uses the upstream directive definition to load balance
	  proxy_ssl_certificate     /opt/equinix/metal/tmp/public.crt;
	  proxy_ssl_certificate_key /opt/equinix/metal/tmp/private.key;
	  proxy_ssl_verify       off;
	  proxy_ssl_session_reuse on;
   }
}
upstream object_private_$LBGROUP_PORT {
   least_conn;

EOL
	for i in $(seq 2 $LBGROUP_LAST); do
		echo "server "$LBGROUP_FIRSTNAME""$i"."$LBGROUP_LASTNAME":9000;" >> /etc/nginx/sites-enabled/$LBGROUP_PORT.conf
	done
	echo "  }" >>/etc/nginx/sites-enabled/$LBGROUP_PORT.conf
done

		cat > /etc/nginx/sites-enabled/export.conf << EOL
server {
   listen       9981;
   server_name  $HOST_TYPE-$MINIO_INSTANCE.$MINIO_DOMAIN;
   root 		/opt/equinix/metal/tmp/export/;

   location /export {
   index index.html;
   autoindex on;
   }
}

EOL

systemctl enable --now nginx
systemctl restart nginx
fi
