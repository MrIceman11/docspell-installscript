
#Create Random Passwords

$POSTGRES_PASSWORD=$(openssl rand -base64 32)

#Update and Upgrade
apt update && apt full-upgrade

#Install Requirements
apt install curl htop zip gnupg2 ca-certificates sudo
apt install default-jdk apt-transport-https wget -y
apt install ghostscript tesseract-ocr tesseract-ocr-deu tesseract-ocr-eng unpaper unoconv wkhtmltopdf ocrmypdf

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
curl https://nc.cloudistboese.de/index.php/s/teWBKk4xBeo6bXA/download > solr-8.11.1.tgz
tar xzf solr-8.11.1.tgz
bash solr-8.11.1/bin/install_solr_service.sh solr-8.11.1.tgz
systemctl start solr
su solr -c '/opt/solr-8.11.1/bin/solr create -c docspell'

#Postgres Install
curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ bullseye-pgdg main" > /etc/apt/sources.list.d/postgresql.list'
apt update && apt full-upgrade
apt install postgresql-14

#Configure Postgres
sudo -u postgres psql -c "CREATE USER docspell WITH SUPERUSER CREATEDB CREATEROLE PASSWORD '$POSTGRES_PASSWORD';"
sudo -u postgres psql -c "CREATE DATABASE docspelldb WITH OWNER docspell;"

systemctl enable postgresql

#Install Docspell
cd /tmp
 
## ASK GITHUB API FOR LATEST RELEASE ADD

wget https://github.com/eikek/docspell/releases/download/v0.36.0/docspell-joex_0.36.0_all.deb
wget https://github.com/eikek/docspell/releases/download/v0.36.0/docspell-restserver_0.36.0_all.deb
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

#Configure Docspell

sed -i 
