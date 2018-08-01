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
	
	