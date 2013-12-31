FtpPublisher
============

This is a tool to publish web applications to an ftp server


Example
============
ruby ftp_publisher.rb  -s /c/git/website/ -d public_html/ -f ftp-credentials.txt -r rules.json

-The rules file is a json that indicates what files to ignore.
--TO DO: Replace files for other files when publishing
--TO DO: Allow regex? so you can exclude by extension

Example of rules.json file
==========================
{
    "c:/git/website/.gitignore": false,
    "c:/git/website/.htaccess": false
    "c:/git/website/some/folder": false
}

Both files will be ignored.
All the folder content will be ignored.