https://blog.csdn.net/jxdl6655/article/details/78194191

vi /etc/hosts
127.0.0.1 HOSTNAME



yum install -y gcc-c++ unixODBC unixODBC-devel openssl-devel ncurses-devel perl
cd /home
tar -xvf otp_src_20.3.tar.gz
cd otp_src_20.3
./configure --prefix=/usr/local/bin/erlang --without-javac
make && make install
cd /home
tar -xvf rabbitmq-server-generic-unix-3.6.15.tar -C /usr/local/bin/
echo 'export PATH=$PATH:/usr/local/bin/erlang/bin:/usr/local/bin/rabbitmq_server-3.6.15/sbin' >> /etc/profile
source /etc/profile


rabbitmq-plugins enable rabbitmq_management


scp /root/.erlang.cookie root@IP:/root


rabbitmqctl stop
rabbitmq-server -detached


rabbitmqctl add_user admin 1q2w3e4r
rabbitmqctl set_permissions -p "/" admin ".*" ".*" ".*"
rabbitmqctl set_user_tags admin administrator
http://ip:15672

node2# rabbitmqctl stop_app

node2# rabbitmqctl join_cluster rabbit@project

node2# rabbitmqctl start_app

rabbitmqctl cluster_status

#打印有效配置
rabbitmqctl environment

vi /usr/local/bin/rabbitmq_server-3.6.15/etc/rabbitmq/rabbitmq-env.conf
#长域名
[
  {rabbit, [{RABBITMQ_USE_LONGNAME, [true]}]}
].

vi /usr/local/bin/rabbitmq_server-3.6.15/etc/rabbitmq/rabbitmq.config
#集群
[
 {rabbit, [
           {cluster_nodes, {['rabbit@es01',
                             'rabbit@es02',
                             'rabbit@es03'], disc}}
          ]}
].

epmd -kill