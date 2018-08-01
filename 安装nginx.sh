一、安装Nginx
	#	cd /usr/local/src
	#	wget http://nginx.org/download/nginx-1.10.3.tar.gz
	#	tar zxvf nginx-1.10.3.tar.gz
	#	cd nginx-1.10.3
	#	./configure --prefix=/usr/local/nginx
	#	make
	#	make install
	编写Nginx启动脚本，并假如系统服务，命令如下：
	#	vim /etc/init.d/nginx	//写入如下内容：
#!/bin/bash
# chkconfig: - 30 21
# description: http service.
# Source Function Library
. /etc/init.d/functions
# Nginx Settings

NGINX_SBIN="/usr/local/nginx/sbin/nginx"
NGINX_CONF="/usr/local/nginx/conf/nginx.conf"
NGINX_PID="/usr/local/nginx/logs/nginx.pid"
RETVAL=0
prog="Nginx"

start() 
{
    echo -n $"Starting $prog: "
    mkdir -p /dev/shm/nginx_temp
    daemon $NGINX_SBIN -c $NGINX_CONF
    RETVAL=$?
    echo
    return $RETVAL
}

stop() 
{
    echo -n $"Stopping $prog: "
    killproc -p $NGINX_PID $NGINX_SBIN -TERM
    rm -rf /dev/shm/nginx_temp
    RETVAL=$?
    echo
    return $RETVAL
}

reload()
{
    echo -n $"Reloading $prog: "
    killproc -p $NGINX_PID $NGINX_SBIN -HUP
    RETVAL=$?
    echo
    return $RETVAL
}

restart()
{
    stop
    start
}

configtest()
{
    $NGINX_SBIN -c $NGINX_CONF -t
    return 0
}

case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  reload)
        reload
        ;;
  restart)
        restart
        ;;
  configtest)
        configtest
        ;;
  *)
        echo $"Usage: $0 {start|stop|reload|restart|configtest}"
        RETVAL=1
esac

exit $RETVAL
	保存该脚本后更改权限，命令如下：
	#	chmod 755 /etc/init.d/nginx
	#	chkconfig -add nginx
	如果像开机启动Nginx，命令如下：
	#	chkconfig nginx on
	更改Nginx的配置文件。
	首先把原来的配置文件清空，
	#	> /usr/local/nginx/conf/nginx.conf
	#	vim /usr/local/nginx/conf/nginx.conf
user nobody nobody;
worker_processes 2;
error_log /usr/local/nginx/logs/nginx_error.log crit;
pid /usr/local/nginx/logs/nginx.pid;
worker_rlimit_nofile 51200;

events
{
    use epoll;
    worker_connections 6000;
}

http
{
    include mime.types;
    default_type application/octet-stream;
    server_names_hash_bucket_size 3526;
    server_names_hash_max_size 4096;
    log_format combined_realip '$remote_addr $http_x_forwarded_for [$time_local]'
    ' $host "$request_uri" $status'
    ' "$http_referer" "$http_user_agent"';
    sendfile on;
    tcp_nopush on;
    keepalive_timeout 30;
    client_header_timeout 3m;
    client_body_timeout 3m;
    send_timeout 3m;
    connection_pool_size 256;
    client_header_buffer_size 1k;
    large_client_header_buffers 8 4k;
    request_pool_size 4k;
    output_buffers 4 32k;
    postpone_output 1460;
    client_max_body_size 10m;
    client_body_buffer_size 256k;
    client_body_temp_path /usr/local/nginx/client_body_temp;
    proxy_temp_path /usr/local/nginx/proxy_temp;
    fastcgi_temp_path /usr/local/nginx/fastcgi_temp;
    fastcgi_intercept_errors on;
    tcp_nodelay on;
    gzip on;
    gzip_min_length 1k;
    gzip_buffers 4 8k;
    gzip_comp_level 5;
    gzip_http_version 1.1;
    gzip_types text/plain application/x-javascript text/css text/htm 
    application/xml;

    server
    {
        listen 80;
        server_name localhost;
        index index.html index.htm index.php;
        root /usr/local/nginx/html;

        location ~ \.php$ 
        {
            include fastcgi_params;
            fastcgi_pass unix:/tmp/php-fcgi.sock;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME /usr/local/nginx/html$fastcgi_script_name;
        }    
    }
}
	检查配置文件是否有错误，命令如下：
	#	/usr/local/nginx/sbin/nginx -t
	启动Nginx，命令如下：
	#	service nginx start
	如果不能启动，查看/usr/local/nginx/logs/error.log文件，检查Nginx是否以启动，命令如下：
	#	ps aux|grep nginx
二、Nginx配置
1、默认虚拟主机
	修改主配置文件nginx.conf，在结束符号｝上面加入一行配置，改写如下：
		include vhost/*.conf;
	}
	意思是，/usr/local/nginx/conf/vhost/下面的所有以.conf结尾的文件都会加载，这样我们就可以把所有虚拟主机配置文件放到vhost目录下面了。
	#	mkdir /usr/local/nginx/conf/vhost
	#	cd /usr/local/nginx/conf/vhost
	#	vim default.conf
	server
	{
		listen 80 default_server;  //有这个标记的就是默认虚拟主机
		server_name aaa.com;
		index index.html index.htm index.php;
		root /data/nginx/default;
	}
	#	/usr/local/nginx/sbin/nginx -t
	#	/usr/local/nginx/sbin/nginx -s reload
	#	echo "default_server" > /data/nginx/default/index.html
2、用户认证
	创建一个新的虚拟主机：
	#	cd /usr/local/nginx/conf/vhost/
	#	vim test.com.conf //加入如下内容
	server
	{
		listen 80;
		server_name test.com;
		index index.html index.htm index.php;
		root /data/nginx/test.com;
		
		location /
		{
			auth_basic				"Auth";
			auth_basic_user_file	/usr/local/nginx/conf/htpasswd;
		}
	}
	#	yum install -y httpd
	#	htpasswd -c /usr/local/nginx/conf/htpasswd aming
	//输入密码
	#	/usr/local/nginx/sbin/nginx -t
	#	/usr/local/nginx/sbin/nginx -s reload
	核心配置语句就两行，auth basic打开认证，auth_basic_user_file指定用户密码文件。
	如果是针对某个目录做认证，需要修改location后面的路径：
	location /admin/
	{
		auth_basic					"Auth";
		auth_basic_user_file 		/usr/local/nginx/conf/htpasswd;
	}
3、域名重定向
	server
	{
		listen 80;
		server_name test.com test1.com test2.com;
		index	index.html index.htm index.php;
		root /data/nginx/test.com;
		
		if	($host != 'test.com') {
			rewrite ^/(.*)$ http://test.com/$1 permanent;
		}
	}
	在Nginx配置中，server_name后面可以跟多个域名，permanent为永久重定向，相当于httpd的R=301。另外还有一个常用的redirect，相当于httpd的R=302。
4、Nginx的访问日志
	#	grep -A2 log_format /usr/local/nginx/conf/nginx.conf
			log_format combined_realip '$remote_addr $http_x_forwarded_for [$time_local]'
			' $host "$request_uri" $status'
			' "$http_referer" "$http_user_agent"';
	和httpd类似，也是在主配置文件中定义日志格式。combined_realip为日志格式的名字，后面可以调用它；$remote_addr为访问网站的用户的出口IP;$http_x_forwarded_for为代理服务器的IP，如果使用了代理，则会记录代理的IP；$time_local为当前的时间；$host为访问的主机名；$request_uri为访问的URL地址；$status为状态码；$http_referer为referer地址；$http_user_agent为user_agent。
	在虚拟主机配置文件中指定访问日志的路径：
	server
	{
		listen 80;
		server_name test.com test1.com test2.com;
		index	index.html index.htm index.php;
		root /data/nginx/test.com;
		
		if	($host != 'test.com') {
			rewrite ^/(.*)$ http://test.com/$1 permanent;
		}
		access_log /tmp/1.log combined_realip;
	}
	使用access_log来指定日志的存储路径，最后面指定日志的格式名字。
	Nginx日志切割脚本：
	#	vim /usr/local/sbin/nginx_log_rotate.sh
#! /bin/bash
## 假设nginx的日志存放路径为/data/logs/
d=`date -d "-1 day" +%Y%m%d` 
logdir="/data/logs"
nginx_pid="/usr/local/nginx/logs/nginx.pid"
cd $logdir
for log in `ls *.log`
do
    mv $log $log-$d
done
/bin/kill -HUP `cat $nginx_pid`
	写完脚本，添加任务计划
	0 0 * * * /bin/bash /usr/local/sbin/nginx_log_rotate.sh
5、配置静态文件不记录日志并添加过期时间
	虚拟主机配置文件改成如下：
	server
	{
		listen 80;
		server_name test.com test1.com test2.com;
		index index.html index.htm index.php;
		root /data/nginx/test.com;
		
		if ($host != 'test.com' ) {
			rewrite ^/(.*)$ http:///test.com/$1 permanent;
		}
		location ~ .*\.(gif|jpg|jpeg|png|bmp|swf)$
		{
			expires 	7d;
			access_log  off;
		}
		location ~ .*\.(js|css)$
		{
			expires		12h;
			access_log 	off;
		}
		access_log /tmp/1.log combined_realip;
	}
	使用location~可以指定对应的静态文件，expires配置过期时间，而access_log配置为off就可以不记录访问日志了。

