#!/bin/sh

#http://blog.endpoint.com/2013/05/gnupg-list-all-recipients-of-message.html
gpg --list-only --no-default-keyring --secret-keyring /dev/null $@
