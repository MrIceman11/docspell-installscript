# docspell-installscript
This Script installs docspell on a debian based system. It is tested on debian 11. It should work on other debian based systems as well.

## Usage
### 1. Download the script
```
git clone https://github.com/MrIceman11/docspell-installscript
```
### 2. Make the script executable
```
chmod +x install.sh
```
### 3. Run the script
```
./install.sh
```
## Info
At the end the scirpt ask you for a Certificat credantials. It is a self-signt Cert, you can skip it with press enter.

Wenn the Script finished, it gives you the URL to the docspell and the uses DP Password. The user for the db is docspell.

## Troubleshooting
It is possible that the script fails. If this happens, you can run the script again. It will skip the steps that are already done.

You may sometimes need to restart your system.
