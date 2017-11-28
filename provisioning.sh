#!/bin/bash

#### ====> Install required packages <=======================================
sudo apt update
sleep 60
sudo apt-get -y install software-properties-common python-software-properties
sleep 10

sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
# preaccept Oracle license
echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections
echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections
#install the java8
sudo apt-get -y install oracle-java8-installer
sudo java -version
sudo apt-get install -y nginx
sleep 10


#### ====> Create a path and install jetty-distribution-9 <============================================
sudo apt-get install -y unzip
sleep 10
sudo wget http://central.maven.org/maven2/org/eclipse/jetty/jetty-distribution/9.3.22.v20171030/jetty-distribution-9.3.22.v20171030.zip -P /home/ubuntu/
sleep 60
sudo unzip /home/ubuntu/jetty-distribution-9.3.22.v20171030.zip
sleep 60
sudo mv jetty-distribution-9.3.22.v20171030 /var/www/jetty
sleep 20
cd /var/www/jetty/demo-base/

#### ====> copy the default file which pass the proxy 8080 to port 80 <===================================
sudo rm -f /etc/nginx/sites-available/default
sudo rm -f /etc/nginx/sites-enabled/default
sudo cp /home/ubuntu/demo/default /etc/nginx/sites-available/default
sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

#### ====> Set cloud instance's PUBLIC_IP as environment variable to be used in static URL to render css  <============================================
#export PUBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4) >> /home/ubuntu/.bash_profile
#sleep 10                          # Wait for environment variable to be properly set

#### ====> Restart the jetty webserver and ngnix service after cp the default file
sudo java -jar ../start.jar &
sleep 30
sudo service nginx restart

