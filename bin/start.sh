#!/bin/bash

service php5-fpm start
/opt/openresty/bin/openresty -g "daemon off;"