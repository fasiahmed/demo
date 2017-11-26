Provisioner.sh file
---------------------------
This is an executable file which execute the software in the EC2 instaces

step1: Install the required packages
       a. java
       b. nginx
       c. unzip

step2: install jetty-distribution-9.3.22
step3: unzip and move the jetty folder to /var/www/jetty
step4: Go to /var/www/jetty/demo-base/ location and start the jetty server
       java -jar ../start.jar
step5: remove the default file and softlink from /etc/nginx/sites-available/default
step6: create a default file at /etc/nginx/sites-available/default
         default
        ---------
       server {
       listen 80;

       location / {
              proxy_pass "http://127.0.0.1:8080";
             #  try_files $uri $uri/ =404;
              }
         }
step 7: create a softlink to default 
         sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

step 8: restart the nginx server
        sudo /etc/init.d/ngnix restart

main.tf
-------------
   provider:           AWS
   availablilityzone:  eu-central-1b
   vpc:       172.16.0.0/16
   subnet:    172.16.10.0/24
   instances: server1 and server2



