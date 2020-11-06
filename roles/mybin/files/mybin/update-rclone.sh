#!/bin/bash
sudo systemctl stop sftp webdav
curl https://rclone.org/install.sh | sudo bash
sudo systemctl start sftp webdav
