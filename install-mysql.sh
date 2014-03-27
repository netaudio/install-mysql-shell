#!/bin/bash

#安装mysql

lsdir=$(pwd)
mysqlnamegz="mysql-5.6.15.tar.gz"
mysqlname="mysql-5.6.15"

ncursesnamegz="ncurses-5.9.tar.gz"
ncursesname="ncurses-5.9"

bisonnamegz="bison-3.0.2.tar.gz"
bisonname="bison-3.0.2"

gmockzp="gmock-1.6.0.zip"
gmock="gmock-1.6.0"

info_log="${lsdir}/install.log"
err_log="${lsdir}/err.log"

rm -rf ${info_log} ${err_log}
pkill mysql

echo '-----------卸载旧的MySQL相关-----------'|tee -a ${info_log}

mysql_rpm=`rpm -qa|grep -i mysql`
if [ ${mysql_rpm} ];
then
    subindex=`expr index ${mysql_rpm} " "`
fi

if [ -z ${mysql_rpm} ];
then
    echo '-----------未安装MySQL-----------'|tee -a ${info_log}
elif [ ${subindex} -le 0 ];
then
    echo "需要卸载: ${mysql_rpm}"|tee -a ${info_log}
    rpm -e --nodeps ${mysql_rpm} 1>>${info_log} 2>>${err_log}
    echo '-----------卸载MySQL完成-----------'|tee -a ${info_log}
else
    mysql_rpm_array=(${mysql_rpm})

    for a in ${mysql_rpm_array[@]}
    do
        echo "需要卸载: ${a}" | tee -a ${info_log}
        rpm -e --nodeps ${a} 1>>${info_log} 2>>${err_log}
    done
    echo '-----------卸载MySQL完成-----------' | tee -a ${info_log}
fi

echo '-----------开始编译ncurses-----------' | tee -a ${info_log}
tar -zxf ${lsdir}/${ncursesnamegz} -C ${lsdir}
cd ${lsdir}/${ncursesname}
./configure --prefix=/usr/local/ncurses 1>>${info_log} 2>>${err_log}
make -j4 1>>${info_log} 2>>${err_log}
make install 1>>${info_log} 2>>${err_log}
cd ..
echo '-----------编译ncurses完成-----------' | tee -a ${info_log}


echo '-----------开始编译bison-----------' | tee -a ${info_log}
tar -zxf ${lsdir}/${bisonnamegz} -C ${lsdir}
cd ${lsdir}/${bisonname}
./configure --prefix=/usr/local/bison 1>>${info_log} 2>>${err_log}
make -j4 1>>${info_log} 2>>${err_log}
make install 1>>${info_log} 2>>${err_log}
cp /usr/local/bison/bin/bison /usr/bin/
cd ..
echo '-----------编译bison完成-----------' | tee -a ${info_log}


echo '-----------开始安装MySQL-----------' | tee -a ${info_log}
tar -zxf ${lsdir}/${mysqlnamegz} -C ${lsdir} 1>>${info_log} 2>>${err_log}
unzip ${lsdir}/${gmockzp} -d ${lsdir}
cd ${lsdir}/${mysqlname}
mkdir "source_downloads"
cp -r ${lsdir}/${gmock} "${lsdir}/${mysqlname}/source_downloads/"

cmake -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DMYSQL_DATADIR=/data/mysql\
-DSYSCONFDIR=/usr/local/mysql/etc/ \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DEXTRA_CHARSETS=gbk \
-DMYSQL_UNIX_ADDR=/tmp/mysqld.sock \
-DWITH_READLINE=1 \
-DWITH_DEBUG=OFF \
-DWITH_EMBEDDED_SERVER=OFF \
-DWITH_CLIENT_LDFLAGS=-ALL-STATIC \
-DWITH_MYSQLD_LDFLAGS=-ALL-STATIC \
-DENABLED_LOCAL_INFILE=1 \
-DWITH_EMBEDDED_SERVER=0 \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_PARTITION_STORAGE_ENGINE=1 \
-DWITH_FEDERATED_STORAGE_ENGINE=0 \
-DWITH_ARCHIVE_STORAGE_ENGINE=0 \
-DWITH_BLACKHOLE_STORAGE_ENGINE=0 \
-DENABLE_DOWNLOADS=1 1>>${info_log} 2>>${err_log}

make -j4 1>>${info_log} 2>>${err_log}
make install 1>>${info_log} 2>>${err_log}

echo '-----------初始化mysql数据库-----------' | tee -a ${info_log}
mkdir -p /data/mysql
mkdir -p /usr/local/mysql/etc
chown -Rv mysql:mysql /data/mysql/ 1>>${info_log} 2>>${err_log}
cd /usr/local/mysql
cp support-files/my-default.cnf /usr/local/mysql/etc/my.cnf
cp support-files/mysql.server /etc/init.d/mysqld
./scripts/mysql_install_db --user=mysql --skip-name-resolve --datadir=/data/mysql --defaults-file=/usr/local/mysql/etc/my.cnf --basedir=/usr/local/mysql 1>>${info_log} 2>>${err_log}
chmod +x /etc/init.d/mysqld 1>>${info_log} 2>>${err_log}

#修改启动脚本里的参数
cp ${lsdir}/mysqld /etc/init.d/mysqld

# 启动mysql后才能修改密码
/etc/init.d/mysqld start 1>>${info_log} 2>>${err_log}
/usr/local/mysql/bin/mysqladmin  -uroot password 123456
echo '-----------初始化mysql数据库完毕-----------' | tee -a ${info_log}


echo '-----------设置mysql开机启动-----------' | tee -a ${info_log}
chkconfig --add mysqld
chkconfig --level 3 mysqld on
echo '-----------设置mysql开机启动-----------' | tee -a ${info_log}


echo '-----------MySQL安装完成-----------' | tee -a ${info_log}

