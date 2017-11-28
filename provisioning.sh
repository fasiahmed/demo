#!/bin/bash

#### ====> Install required packages
sudo apt update
sleep 60
sudo apt-get -y install software-properties-common python-software-properties
sleep 10
sudo add-apt-repository -y ppa:webupd8team/java
sudo apt update
sleep 60
sudo apt-get -y install oracle-java8-installer
sudo java -version
sudo apt-get install -y nginx
sleep 10


#### ====> Create a path and install jetty-distribution-9
sudo apt-get install -y unzip
sleep 10
sudo wget http://central.maven.org/maven2/org/eclipse/jetty/jetty-distribution/9.3.22.v20171030/jetty-distribution-9.3.22.v20171030.zip -P /home/ubuntu/
sudo unzip /home/ubuntu/jetty-distribution-9.3.22.v20171030.zip

sudo mv jetty-distribution-9.3.22.v20171030 /var/www/jetty
cd /var/www/jetty/demo-base/
sudo java -jar ../start.jar &
#### ====> Copy the builds to respective folders of tw-docker-infra for use in docker containers
sudo rm -f /etc/nginx/sites-available/default
sudo rm -f /etc/nginx/sites-enabled/default
sudo cp /home/ubuntu/demo/default /etc/nginx/sites-available/default
sleep 10
sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
sleep 20                           # Wait until the builds are copied

#### ====> Set cloud instance's PUBLIC_IP as environment variable to be used in static URL to render css
#export PUBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4) >> /home/ubuntu/.bash_profile
#sleep 10                          # Wait for environment variable to be properly set

#### ====> Restart the ngnix service after cp the default file
sudo /etc/init.d/ngnix restart

