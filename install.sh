#Create Random Passwords

POSTGRES_PASSWORD=$(openssl rand -base64 32)

#Update and Upgrade
apt update && apt full-upgrade -y

#Install Requirements
apt install curl htop zip gnupg2 ca-certificates sudo -y
apt install default-jdk apt-transport-https wget -y
apt install ghostscript tesseract-ocr tesseract-ocr-deu tesseract-ocr-eng unpaper unoconv wkhtmltopdf ocrmypdf -y

#Create and Write a new File

cat > /etc/systemd/system/unoconv.service <<EOF
[Unit]
Description=Unoconv listener for document conversions
Documentation=https://github.com/dagwieers/unoconv
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=simple
Environment="UNO_PATH=/usr/lib/libreoffice/program"
ExecStart=/usr/bin/unoconv --listener

[Install]
WantedBy=multi-user.target
EOF

systemctl enable unoconv.service

# Install Solr
cd /home
curl https://cloud.altmann.network/s/PzJcpLn4jGoojLm/download > solr-8.11.1.tgz
tar xzf solr-8.11.1.tgz
bash solr-8.11.1/bin/install_solr_service.sh solr-8.11.1.tgz

systemctl start solr

su solr -c '/opt/solr-8.11.1/bin/solr create -c docspell'

#Postgres Install
curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main" > /etc/apt/sources.list.d/postgresql.list'
apt update && apt full-upgrade
apt install postgresql-14 -y

#Configure Postgres
sudo -u postgres psql -c "CREATE USER docspell WITH SUPERUSER CREATEDB CREATEROLE PASSWORD '$POSTGRES_PASSWORD';"
sudo -u postgres psql -c "CREATE DATABASE docspelldb WITH OWNER docspell;"

systemctl enable postgresql

#Install Docspell
cd /tmp
 
## ASK GITHUB API FOR LATEST RELEASE ADD

docspell_joex=$(curl -s https://api.github.com/repos/eikek/docspell/releases/latest | grep "browser_download_url" | cut -d : -f 2,3 | tr -d \" | grep .deb | grep docspell-joex)
docspell_restserver=$(curl -s https://api.github.com/repos/eikek/docspell/releases/latest | grep "browser_download_url" | cut -d : -f 2,3 | tr -d \" | grep .deb | grep docspell-restserver)

wget $docspell_joex
wget $docspell_restserver

#wget https://github.com/eikek/docspell/releases/download/v0.36.0/docspell-joex_0.36.0_all.deb
#wget https://github.com/eikek/docspell/releases/download/v0.36.0/docspell-restserver_0.36.0_all.deb
dpkg -i docspell*

service docspell-restserver stop
service docspell-joex stop

mkdir /home/docspell
mkdir /home/docspell/.cache
touch /home/docspell/.cache/dconf
chown -R docspell:docspell /home/docspell/

cd /home
wget https://github.com/docspell/dsc/releases/download/v0.9.0/dsc_amd64-musl-0.9.0
mv dsc_amd* dsc
chmod +x dsc
mv dsc /usr/bin

#Configure Docspell (restserver)
sed -i '356s|url = "jdbc:postgresql://server:5432/db"|url = "jdbc:postgresql://localhost:5432/docspelldb"|' /etc/docspell-restserver/docspell-server.conf
sed -i '357s|user = "pguser"|user = "docspell"|' /etc/docspell-restserver/docspell-server.conf
sed -i '358s|password = ""|password = "'$POSTGRES_PASSWORD'"|' /etc/docspell-restserver/docspell-server.conf

sed -i '401s|url = "jdbc:h2://"${java.io.tmpdir}"/docspell-demo.db;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;AUTO_SERVER=TRUE"|url = "jdbc:postgresql://localhost:5432/docspelldb"|' /etc/docspell-restserver/docspell-server.conf
sed -i '404s|user = "sa"|user = "docspell"|' /etc/docspell-restserver/docspell-server.conf
sed -i '407s|password = ""|password = "'$POSTGRES_PASSWORD'"|' /etc/docspell-restserver/docspell-server.conf

#enable Full Text Search (geht)
sed -i '327s/    enabled = false/    enabled = true/' /etc/docspell-restserver/docspell-server.conf

#Configure Docspell (joex)

sed -i '49s|url = "jdbc:h2://"${java.io.tmpdir}"/docspell-demo.db;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;AUTO_SERVER=TRUE"|url = "jdbc:postgresql://localhost:5432/docspelldb"|' /etc/docspell-joex/docspell-joex.conf
sed -i '52s|user = "sa"|user = "docspell"|' /etc/docspell-joex/docspell-joex.conf
sed -i '55s|password = ""|password = "'$POSTGRES_PASSWORD'"|' /etc/docspell-joex/docspell-joex.conf

#edit pool-size (geht)
sed -i '99s/    pool-size = 1/    pool-size = 8/' /etc/docspell-joex/docspell-joex.conf

# Nginx

apt install nginx -y

openssl dhparam -out /etc/nginx/dhparam.pem 2048 -batch
mkdir /etc/nginx/ssl
openssl req -x509 -nodes -days 60000 -newkey rsa:2048 -keyout /etc/nginx/ssl/docs.home.key -out /etc/nginx/ssl/docs.home.crt

curl https://raw.githubusercontent.com/andreklug/docspell-debian/main/nginx-default > /etc/nginx/sites-enabled/default

# Auskommentieren von Zeile /etc/ngnix/ssl/homelab.local_CA.crt

sed -i 's/ssl_trusted_certificate/#ssl_trusted_certificate/' /etc/nginx/sites-enabled/default

service nginx restart

#Start Docspell
service docspell-restserver start
service docspell-joex start

#Get Local IP
IP=$(hostname -I | cut -d' ' -f1)

#Abschluss
echo "Docspell is now installed and running. Please visit https://$IP/app configure your instance."
echo "Your Postgres Password is: $POSTGRES_PASSWORD"
