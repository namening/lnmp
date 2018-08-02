一、安装php-fpm
	针对Nginx的PHP安装和上一章的PHP安装是有区别的。因为Nginx中的PHP是以fastcgi的方式结合Nginx的，可以理解为Nginx代理了PHP的fastcgi，而httpd是把PHP作为自己的模块来调用的。PHP的官方下载地址为：http://www.php.net/downloads.php
	#	cd /usr/local/src
	#	wget http://cn2.php.net/distributions/php-5.6.32.tar.bz2
	#	tar jxf php-5.6.32.tar.bz2
	#	useradd -s /sbin/nologin php-fpm
	该帐号用来运行php-fpm服务。在LNMP环境中，PHP以一个服务php-fpm的形式出现，独立存在于linux系统中，方便管理。
	配置编译选项，命令如下：
	#	cd php-5.6.32
	#	./configure \
	--prefix=/usr/local/php-fpm \
	--with-config-file-path=/usr/local/php-fpm/etc \
	--enable-fpm \
	--with-fpm-user=php-fpm \
	--with-fpm-group=php-fpm \
	--with-mysql=/usr/local/mysql \
	--with-mysql-sock=/tmp/mysql.sock \
	--with-libxml-dir \
	--with-gd \
	--with-jpeg-dir \
	--with-png-dir \
	--with-freetype-dir \
	--with-iconv-dir \
	--with-zlib-dir \
	--with-mcrypt \
	--enable-soap \
	--enable-gd-native-ttf \
	--enable-ftp \
	--enable-mbstring \
	--enable-exif \
	--disable-ipv6 \
	--with-pear \
	--with-curl \
	--with-openssl
	编译参数和上一章不同，多了一个--enable-fpm,如果不加该参数，则不会有php-fpm执行文件生成，更不能启动php-fpm服务。
	错误信息：
	configure：error：Please reinstall the libcurl distribution -
		easy.h should be in <curl-dir>/include/curl/
	其解决办法如下
	#	yum install -y libcurl-devel
	编译PHP，命令如下：
	#	make
	在这一步，你通常会遇到一些错误。
	/usr/bin/ld: TSRM/.libs/TSRM.o: undefined reference to symbol 'pthread_sigmask@@GLIBC_2.2.5'
	/usr/lib64/libpthread.so.0: error adding symbols:DSO missing from command line
	collect2: error:ld returned 1 exit status
	make: *** [sapi/cli/php] 错误 1
	解决办法：
	#	vim Makefile
	// 在大概102行，-lcrypt后面加“-lpthread”
	继续make，然后又遇到错误
	collect2：error：ld returned 1 exit status
	make：*** [sapi/cli/php] 错误1
	解决方法如下：
	#	make clean && make
	安装PHP,
	# 	make install
	修改配置文件，命令如下：
	#	cp php.ini-production /usr/local/php-fpm/etc/php.ini
	#	vim /usr/local/php-fpm/etc/php-fpm.conf
	把如下内容写入该文件：
	[global]
	pid = /usr/local/php-fpm/var/run/php-fpm.pid
	error_log = /usr/local/php-fpm/var/log/php-fpm.log
	[www]
	listen = /tmp/php-fcgi.sock
	listen.mode = 666
	user = php-fpm
	group = php-fpm
	pm = dynamic
	pm.max_children = 50
	pm.start_servers = 20
	pm.min_spare_servers = 5
	pm.max_spare_servers = 35
	pm.max_requests = 500
	rlimit_files = 1024
	保存配置文件后，检测配置是否正确：
	#	/usr/local/php-fpm/sbin/php-fpm -t
	启动php-fpm,命令如下：
	#	cp /usr/local/src/php-5.6.30/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
	#	chmod 755 /etc/init.d/php-fpm
	#	useradd -s /sbin/nologin php-fpm
	#	service php-fpm start
	设置php-fpm开机启动：
	#	chkconfig php-fpm on
	检查php-fpm是否启动
	#	ps aux|grep php-fpm
	执行这条命令，可以看到启动了很多个进程
二、php-fpm配置
	php-fpm的配置文件为/usr/local/php-fpm/etc/php-fpm.conf,同样支持include语句，类似于nginx.conf里面的include。
1、php-fpm的pool
	Nginx可以配置多个虚拟主机，php-fpm同样也支持配置多个pool，每一个pool可以监听一个端口，也可以监听一个socket。
[global]
pid = /usr/local/php-fpm/var/run/php-fpm.pid
error_log = /usr/local/php-fpm/var/log/php-fpm.log
include = etc/php-fpm.d/*.conf
	include的这一行比较特殊，请注意等号后面的路径，必须写上etc目录，然后需要创建配置文件目录和子配置文件：
	#	mkdir /usr/local/php-fpm/etc/php-fpm.d
	#	cd /usr/local/php-fpm/etc/php-fpm.d
	#	vim www.conf
	[www]
	listen = /tmp/www.sock
	listen.mode=666
	user = php-fpm
	group = php-fpm
	pm =dynamic
	pm.max_children = 50
	pm.start_servers = 20
	pm.min_spare_servers = 5
	pm.max_spare_servers = 35
	pm.max_requests = 500
	rlimit_files = 1024
	保存后，再编辑另外的配置文件：
	#	vim aming.conf 
	[aming]
	listen = /tmp/aming.sock
	listen.mode=666
	user = php-fpm
	group = php-fpm
	pm = dynamic
	pm.max_children = 50
	pm.start_servers = 20
	pm.min_spare_servers = 5
	pm.max_spare_servers = 35
	pm.max_requests = 500
	rlimit_files = 1024
	这样就有两个子配置文件，也就是说有2个pool了，第一个pool监听了/tmp/www.sock,第二个pool监听了/tmp/aming.sock。这样，就可以在Nginx不同的虚拟主机中调用不同的pool，从而达到相互隔离的目的，两个pool互不影响。
2、php-fpm的慢执行日志
	查看慢执行日志，操作步骤如下：
	#	vim /usr/local/php-fpm/etc/php-fpm.d/www.conf	//在最后面加入如下内容
	request_slowlog_timeout = 1
	slowlog = /usr/local/php-fpm/var/log/www-slow.log
	第一行定义超时时间，即PHP的脚本执行时间只要超过1秒就会记录日志，第二行定义慢执行日志的路径和名字。
3、php-fpm定义open_basedir
	httpd可以针对每个虚拟主机设置一个open_basedir，php-fpm同样也可以针对不同的pool设置不同的open_basedir。
	#	vim /usr/local/php-fpm/etc/php-fpm.d/aming.conf //在最后面加入如下
	php_admin_value[open_basedir]=/data/www/:/tmp/
	只要在对应的Nginx虚拟主机配置文件中调用对应的pool，就可以使用open_basedir来物理隔离多个站点了，从而达到安全目的。
4、php-fpm进程管理
	来看下这一段配置：
	pm = dynamic
	pm.max_children = 50
	pm.start_servers = 20
	pm.min_spare_servers = 5
	pm.max_spare_servers = 35
	pm.max_requests = 500
	第一行，定义php-fpm的子进程启动模式，dynamic为动态模式;一开始只启动少量的子进程，根据实际需求，动态地增加或者减少子进程，最多不会超过pm.max_children定义的数值。另外一种模式为static，这种模式下子进程数量有pm.max_children决定，一次性启动这么多，不会较少也不会增加。
	pm.start_servers针对dynamic模式，它定义php-fpm服务在启动服务时产生的子进程数量。pm.min_spare_servers针对dynamic模式，它定义在休闲时段子进程数的最少数量，如果达到这个数值时，php-fpm服务会自动派生新的子进程。pm.max_spare_servers也是针对dynamic模式的，它定义在空虚时段子进程数的最大值，如果高于这个数值就开始清理空闲的子进程。pm.max_requests针对dynamic模式，它定义一个子进程最多处理的请求数，也就是说在一个php-fpm的子进程中最多可以处理这么多请求，当达到这个数值是，它会自动退出。

	