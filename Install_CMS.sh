#!/bin/bash
#by pjl

GREEN='\E[1;32m' #绿
RED='\E[1;31m'   #红
RES='\E[0m'

Init() {
	#禁用记录文件访问时间
	#/dev/sdb1 /data1 ext4 defaults,noatime 0
	#mount -o remount /data1

	#关闭selinux
	setenforce 0
	sed -i '/^SELINUX=/c\SELINUX=disabled' /etc/selinux/config

	#关闭防火墙
	systemctl stop firewalld
	systemctl disable firewalld > /dev/null 2>&1

	#禁用Transparent Huge Pages特性
	echo never > /sys/kernel/mm/transparent_hugepage/defrag
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	echo -e "echo never > /sys/kernel/mm/transparent_hugepage/defrag\necho never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.d/rc.local
	chmod +x /etc/rc.d/rc.local

	#不使用swap分区,设置为0-10之间
	sysctl vm.swappiness=0 > /dev/null
	echo "vm.swappiness=0" >> /etc/sysctl.conf
	echo -e "${GREEN}执行完毕~${RES}"
}

Create_SSH() {
	#设置ssh无密码登陆
	ssh-keygen -t rsa
	echo -e "${GREEN}执行完毕~${RES}"
	ll ~/.ssh/
}

Copy_SSH() {
	read -p "请输入需要传输的ip地址：" sship
	ssh-copy-id -i ~/.ssh/id_rsa.pub root@$sship
	echo -e "${GREEN}执行完毕~${RES}"
}

#不使用expect无法传入密码，暂时搁置
#Copy_SSH() {
#	read -p "请输入需要复制SSH密钥服务器的密码：" PASSWORD
#	if [ ! -f "hosts" ]; then
#		echo -e "${RED}请将$0与hosts置于同一目录${RES}"
#		exit 1
#	elif [ -z $PASSWORD ]; then
#		echo -e "${RED}请输入密码${RES}"
#		exit 1
#	fi
#	for ip in $(cat "hosts"); do
#		ssh-copy-id -i ~/.ssh/id_rsa.pub root@$ip
#	done
#	echo -e "${GREEN}执行完毕~${RES}"
#}

Install_JAVA() {
	#安装JAVA并配置环境
	if [ -f jdk-8u*.tar.gz ]; then
		mkdir -p /usr/java/
		tar -xvf jdk-8u*.tar.gz -C /usr/java/
		mv /usr/java/jdk1.8*/ /usr/java/jdk1.8/
		if ! grep "JAVA_HOME=/usr/java/jdk1.8" /etc/profile > /dev/null 2>&1; then
			echo -e '\n#JAVA_PATH\nexport JAVA_HOME=/usr/java/jdk1.8\nexport JRE_HOME=${JAVA_HOME}/jre\nexport CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib\nexport PATH=${JAVA_HOME}/bin:$PATH' >> /etc/profile
		fi
		source /etc/profile
		echo -e "${GREEN}建议执行source /etc/profile命令使JAVA环境立即生效~${RES}"
	else
		echo -e "${RED}当前目录未找到jdk-8u*.tar.gz${RES}"
		#jdk1.8下载链接失效
		#yum -y install wget
		#wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u171-b11/512cd62ec5174c3487ac17c61aaa89e8/jdk-8u171-linux-x64.tar.gz"
	fi
}

Install_NTP() {
	#安装NTP并设置开机启动，后期考虑使用chrony代替NTP
	if [ -d *ntp* ]; then
		echo -e "${GREEN}检测到ntp，开始配置本地yum源${RES}"
		read -p "Do you want to continue [Y/N]?" answer
		case $answer in
		Y | y)
			mkdir /root/yum_bak > /dev/null 2>&1
			mv -f /etc/yum.repos.d/* /root/yum_bak
			cat > /etc/yum.repos.d/ntp.repo <<- 'EOF'
				[local-ntp]
				name=ntp
				baseurl=file:///root/ntp/
				enabled=1
				gpgcheck=0
			EOF
			yum -y install ntp
			echo -e "${GREEN}正在启动ntp，请稍等~${RES}"
			systemctl start ntp
			systemctl enable ntp > /dev/null 2>&1
			\cp -f /root/yum_bak/* /etc/yum.repos.d/
			echo -e "${GREEN}执行完毕~${RES}"
			;;
		N | n)
			echo -e "${GREEN}BYE${RES}"
			;;
		*)
			echo -e "${RED}ERROR${RES}"
			;;
		esac
	else
		yum -y install ntp
		echo -e "${GREEN}正在启动ntp，请稍等~${RES}"
		systemctl start ntpd
		systemctl enable ntpd > /dev/null 2>&1
		echo -e "${GREEN}执行完毕~${RES}"
	fi
}

Install_HTTP() {
	#安装HTTP
	if [ -d *httpd* ]; then
		echo -e "${GREEN}检测到httpd，开始配置本地yum源${RES}"
		read -p "Do you want to continue [Y/N]?" answer
		case $answer in
		Y | y)
			mkdir /root/yum_bak > /dev/null 2>&1
			mv -f /etc/yum.repos.d/* /root/yum_bak
			cat > /etc/yum.repos.d/httpd.repo <<- 'EOF'
				[local-httpd]
				name=httpd
				baseurl=file:///root/httpd/
				enabled=1
				gpgcheck=0
			EOF
			yum -y install httpd
			echo -e "${GREEN}正在启动httpd，请稍等~${RES}"
			systemctl start httpd
			\cp -f /root/yum_bak/* /etc/yum.repos.d/
			echo -e "${GREEN}执行完毕~${RES}"
			;;
		N | n)
			echo -e "${GREEN}BYE${RES}"
			;;
		*)
			echo -e "${RED}ERROR${RES}"
			;;
		esac
	else
		yum -y install httpd
		echo -e "${GREEN}正在启动httpd，请稍等~${RES}"
		systemctl start httpd
		echo -e "${GREEN}执行完毕~${RES}"
	fi
}

Install_MYSQL5.6() {
	#安装MYSQL并设置开机启动
	if [ -d *mysql5.6* ]; then
		echo -e "${GREEN}检测到mysql5.6，开始配置本地yum源${RES}"
		read -p "Do you want to continue [Y/N]?" answer
		case $answer in
		Y | y)
			mkdir /root/yum_bak > /dev/null 2>&1
			mv -f /etc/yum.repos.d/* /root/yum_bak
			cat > /etc/yum.repos.d/mysql56.repo <<- 'EOF'
				# Enable to use MySQL 5.6
				[local-mysql56-community]
				name=MySQL 5.6 Community Server
				baseurl=file:///root/mysql5.6
				enabled=1
				gpgcheck=0
			EOF
			yum -y install mysql-server
			echo -e "${GREEN}正在启动mysqld，请稍等~${RES}"
			systemctl start mysqld
			systemctl enable mysqld > /dev/null 2>&1
			\cp -f /root/yum_bak/* /etc/yum.repos.d/
			#passwd=`grep 'temporary password' /var/log/mysqld.log |awk '{print $NF}'`
			#echo -e  "${GREEN}MYSQL root用户密码为:$passwd${RES}"
			echo -e "${GREEN}请设置MYSQL root用户密码${RES}"
			mysqladmin -u root password
			echo -e "${GREEN}执行完毕~${RES}"
			;;
		N | n)
			echo -e "${GREEN}BYE${RES}"
			;;
		*)
			echo -e "${RED}ERROR${RES}"
			;;
		esac
	else
		cat > /etc/yum.repos.d/mysql56.repo <<- 'EOF'
			# Enable to use MySQL 5.6
			[mysql56-community]
			name=MySQL 5.6 Community Server
			baseurl=http://repo.mysql.com/yum/mysql-5.6-community/el/7/$basearch/
			enabled=1
			gpgcheck=0
		EOF
		yum -y install mysql-server
		echo -e "${GREEN}正在启动mysqld，请稍等~${RES}"
		systemctl start mysqld
		systemctl enable mysqld > /dev/null 2>&1
		echo -e "${GREEN}请设置MYSQL root用户密码${RES}"
		mysqladmin -u root password
		echo -e "${GREEN}执行完毕~${RES}"
	fi
}

Install_CMS() {
	#本地检测到cm安装包
	if [ -d cm* ]; then
		if rpm -qa | grep httpd > /dev/null 2>&1; then
			systemctl restart httpd
			read -p "检测到本机已安装httpd服务，是否建立内网yum源 [Y/N]?" answer
			case $answer in
			Y | y)
				#本地已安装httpd服务，建立cm的内网yum源
				mkdir /root/yum_bak > /dev/null 2>&1
				mv -f /etc/yum.repos.d/* /root/yum_bak
				mv -f cm* cm > /dev/null 2>&1
				\cp -rf cm /var/www/html
				read -p "请输入本机的地址：" localhostip
				#该处EOF加单引号会使localhostip变量失效
				cat > /etc/yum.repos.d/cm.repo <<- EOF
					[local-cm]
					name=Cloudera Manager
					baseurl=http://$localhostip/cm
					enabled=1
					gpgcheck=0
				EOF
				Yum_Install
				\cp -f /root/yum_bak/* /etc/yum.repos.d/
				;;
			N | n)
				#本地已安装httpd服务，但不建立cm的内网yum源
				mkdir /root/yum_bak > /dev/null 2>&1
				mv -f /etc/yum.repos.d/* /root/yum_bak
				mv -f cm* cm > /dev/null 2>&1
				cat > /etc/yum.repos.d/cm.repo <<- 'EOF'
					[local-cm]
					name=Cloudera Manager
					baseurl=file:///root/cm
					enabled=1
					gpgcheck=0
				EOF
				Yum_Install
				\cp -f /root/yum_bak/* /etc/yum.repos.d/
				;;
			*)
				echo -e "${RED}ERROR${RES}"
				;;
			esac
		else
			mkdir /root/yum_bak > /dev/null 2>&1
			mv -f /etc/yum.repos.d/* /root/yum_bak
			mv -f cm* cm > /dev/null 2>&1
			cat > /etc/yum.repos.d/cm.repo <<- 'EOF'
				[local-cm]
				name=Cloudera Manager
				baseurl=file:///root/cm
				enabled=1
				gpgcheck=0
			EOF
			Yum_Install
			\cp -f /root/yum_bak/* /etc/yum.repos.d/
		fi
	else
		#本地未检测到cm安装包
		cat > /etc/yum.repos.d/cloudera-manager.repo <<- 'EOF'
			[cloudera-manager]
			# Packages for Cloudera Manager, Version 5, on RedHat or CentOS 7 x86_64           	  
			name=Cloudera Manager
			baseurl=http://archive.cloudera.com/cm5/redhat/7/x86_64/cm/5.14.2
			enabled=1
			gpgcheck = 0
		EOF
		Yum_Install
	fi
}

Yum_Install() {
	yum -y install cloudera-manager-server cloudera-manager-daemons
	if [ -f *mysql-connector-java* ]; then
		echo -e "${GREEN}检测到mysql-connector-java开始初始化CM5的数据库${RES}"
		\cp -f mysql-connector-java-*.jar /usr/share/cmf/lib/
		mkdir -p /usr/share/java
		\cp -f mysql-connector-java-*.jar /usr/share/java/
		ln -s /usr/share/java/mysql-connector-java-*.jar /usr/share/java/mysql-connector-java.jar
		##全局_jdbc
		#\cp -f mysql-connector-java-*.jar /usr/java/jdk1.8/jre/lib/ext
		#\cp -f mysql-connector-java-*.jar /usr/share/cmf/lib
		#mkdir -p /usr/share/java
		#\cp -f mysql-connector-java-*.jar /usr/share/java/
		#ln -s /usr/share/java/mysql-connector-java-*.jar /usr/share/java/mysql-connector-java.jar
		##hive_jdbc
		#\cp -f mysql-connector-java-*.jar /opt/cloudera/parcels/CDH-5.14.2-1.cdh5.14.2.p0.3/lib/hive/lib
		##oozie_jdbc
		#mkdir -p /usr/share/java
		#\cp -f mysql-connector-java-*.jar /usr/share/java
		#ln -s /usr/share/java/mysql-connector-java-*.jar /usr/share/java/mysql-connector-java.jar
		##oracle_jdbc
		#/usr/share/java/oracle-connector-java.jar
		echo -e "${GREEN}初始化CM5的数据库，请输入数据库服务器的地址${RES}"
		read -p "（默认：localhost回车即可）：" mysqlip
		[ -z "${mysqlip}" ] && mysqlip="localhost"
		/usr/share/cmf/schema/scm_prepare_database.sh mysql scm -h$mysqlip -uroot -p --scm-host localhost scm scm scm
		#sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql scm scm
		#sudo /opt/cloudera/cm/schema/scm_prepare_database.sh mysql -h db01.example.com --scm-host cm01.example.com scm scm
		echo -e "${GREEN}正在启动Cloudera Manager Server，请稍等~${RES}"
		systemctl start cloudera-scm-server
		echo -e "${GREEN}执行完毕~${RES}"
	else
		echo -e "${RED}未检测到mysql-connector-java，请使用命令手动初始化CM5的数据库：/usr/share/cmf/schema/scm_prepare_database.sh mysql scm -h<Mysql Server> -uroot -p --scm-host <Cloudera Manager Server> scm scm scm${RES}"
	fi
}

date
#用户、目录检查
user=$(whoami)
dir=$(dirname $(readlink -f $0))
if [ ! "$user" == "root" ] || [ ! "$dir" == /root ]; then
	echo -e "${RED}当前用户或目录不为root${RES}"
	exit 1
fi
echo -e "\n	${RED}CDH安装脚本${RES}
	${GREEN}1.${RES} 初始化系统环境${RED}[必需]
	${GREEN}2.${RES} 生成SSH密钥
	${GREEN}3.${RES} 复制SSH密钥
	${GREEN}4.${RES} 安装JAVA并配置环境
	${GREEN}5.${RES} 安装NTP服务
	${GREEN}6.${RES} 安装HTTP服务
	${GREEN}7.${RES} 安装MYSQL5.6服务
	${GREEN}8.${RES} 安装Cloudera Manager Server
 "
echo && stty erase '^H' && read -p "请输入数字 [1-8]：" num
case "$num" in
1)
	Init
	;;
2)
	Create_SSH
	;;
3)
	Copy_SSH
	;;
4)
	Install_JAVA
	;;
5)
	Install_NTP
	;;
6)
	Install_HTTP
	;;
7)
	Install_MYSQL5.6
	;;
8)
	Install_CMS
	;;
*)
	echo "请输入正确的数字 [1-8]"
	;;
esac
