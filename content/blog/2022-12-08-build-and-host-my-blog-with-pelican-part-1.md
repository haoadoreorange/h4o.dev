+++
title = "Build & host my blog with Pelican (part 1)"
date = 2022-12-08

[taxonomies]
tags = ["build", "blog", "pelican", "python"]
+++

Hello there, welcome back. This is part 1 of the diary of how I built my blog. Since I index everything from 0, this is already the second blog post of the series. You might want to check out the first before continue.

<!-- more -->

**[← Part 0](/blog/2022/01/25/build-&-host-my-blog-with-pelican-part-0)**

# Getting a server

I won't get into the details here as there is a zillions ways of doing this, and either you know it or you don't. But for those who don't, here are some keywords. Basically, you need a Linux pc connected to the internet with a public address, I host my blog on a VPS instance with OVH, and so far it has been a pretty smooth experience. You also need a domain name, which you can get one on GoogleDomains or Cheapnames, these platforms then allow you to configure a DNS record to point your domain name towards your public address. From here, I assume that my readers are able to connect to their server terminal (e.g. with ssh). I run my server on Ubuntu 22.04 LTS.

# Setting up the server

OVH allows me to set up my server directly with an ssh public key, therefore I don't know my password upon the first login. So before doing anything, I need to configure a password for root & also the regular user, and I need to be doing so as root, since I can't fill in the current password. Luckily, `sudo` requires no password on the instance (because I set it up with a public key I guess ?? ), so I can just do

```sh
sudo su
```

to login as root, from here,

```sh
passwd # to change my root password.
passwd <username> # to change my user password.
```

Once the passwords are properly set, I can activate `sudo` password protection.

```sh
visudo /etc/sudoers.d/90-cloud-init-users
```

Once the text editor shows up, I remove the `NOPASSWORD:` option. On my OVH VPS instance, the sudo configurations made by `cloud-init` in this file override the sudoers file, so we need to modify this file instead. Finally,

```sh
exit # to exit root, our sudo is working properly now.
```

# Security configuration

Once the users are up and running, I begin modifying some system configuration for security purpose. These are the practices I cultivated over the years through different recommendation sources, it is by no mean the absolute best. People on the internet might do it differently, so take mine with a grain of salt, and you do your way.

```sh
sudo passwd -l root # lock the root password, a practice from Ubuntu.
```

In `sshd_config` file, I modify the following entries

```sh
PermitRootLogin no # disable root login through ssh
PasswordAuthentication no
KbdInteractiveAuthentication no
```

The 2 latter entries disable ssh password login completely, making public key the only way to ssh into my server. The second entry is required because password authentication is not the only mechanism that can prompt users for some kind of password. There is always `KbdInteractiveAuthentication`, which is a challenge-response mechanism, usually used by PAM for asking a series of question. In practice though, it often only asks for user password. This defaults to `yes`, and I need to put this option with `no` into the configuration explicitly to disable it.

Some blogs out there recommend `UsePAM no`, I myself don't do it. It is not used only for authentication, but also for setting up session of the user and other steps around authentication. It might work for you now, but it might break in future or for somebody else who will be using a different system.

# Install nginx & certbot

I first update the system

```sh
sudo apt update && sudo apt upgrade
```

There are different ways to serve static site, I use nginx. I install nginx & also certbot (I'll need it later on to request a TLS certificate) following their documentation.

- nginx: [https://nginx.org/en/linux_packages.html#Ubuntu](https://nginx.org/en/linux_packages.html#Ubuntu)
- certbot: [https://certbot.eff.org/instructions?ws=nginx&os=ubuntufocal](https://certbot.eff.org/instructions?ws=nginx&os=ubuntufocal)

As the moment of this writing, the nginx installation by default also create a nginx user used to run its daemon with. This is a security good practice. Ideally, I would want to provide this user with only read access to the files my nginx server need to serve. At the same time, I want write permission for my main user, just in case I want to manually edit something. To achieve this, I create a new shared group between the nginx user and my main user.

```sh
sudo groupadd newgroup
sudo gpasswd -a <username> newgroup
sudo gpasswd -a nginx newgroup
```

I then create a new folder to host my static files under a location where every user can traverse the filesystem (e.g. `/mnt`), change the owner, and give a 2750 permission to it. This is equivalent to all permission for the owner, read & execute permission for the owning group, and 0 permission for other users.

```sh
sudo mkdir /mnt/newfolder
sudo chown <username>:newgroup /mnt/newfolder
sudo chmod 2750 /mnt/newfolder
```

Once this is done, I am ready to configure my nginx server, since it has the required permission to serve the files now.

# Configure nginx & certbot

In order for my nginx server to serve https, I need to request a certificate using `certbot` first. One thing noted here, because I'm setting up a 301 redirection between the `www` and `non-www` domain (i.e. [h4o.dev](https://h4o.dev) redirect to [www.h4o.dev](https://www.h4o.dev), using which one as the main domain is a [never-ending debate](https://duckduckgo.com/?t=ffab&q=www+vs+non-www&ia=web)), I need a certificate for **both** the `www` and `non-www` version. Otherwise, chrome will report a TLS error before the site can get redirected. For everything to work smoothly, I need to put 2 empty `server` block under the `http` block, each with their respective server_name in `/etc/nginx/nginx.conf`.

```sh
server {
    server_name www.h4o.dev
}
server {
    server_name h4o.dev
}
```

Then I enable nginx and run `certbot`

```sh
sudo systemctl enable --now nginx
sudo certbot --nginx
```

`certbot` requests a certificate for me, and thanks to those 2 empty server blocks, it also configures `nginx` for https automatically. Finally, I do need to make some final tweak to my nginx configuration for it to become fully functional to my flavor. This is how my server block look like at the end.

```sh
server {
    server_name www.h4o.dev;

    listen [::]:443 ssl; # managed by Certbot
    listen 443 ssl; # managed by Certbot
    ssl_certificate ... # managed by Certbot
    ssl_certificate_key ... # managed by Certbot
    include ... # managed by Certbot
    ssl_dhparam ... # managed by Certbot

    if ($host != www.h4o.dev) {
        return 404;
    }

    root /mnt/newfolder/;
    rewrite ^/(.+)/$ /$1 permanent;
    try_files $uri $uri.html $uri/index.html =404;
}
server {
    server_name h4o.dev;

    listen [::]:443 ssl; # managed by Certbot
    listen 443 ssl; # managed by Certbot

    return 301 $scheme://www.h4o.dev$request_uri;
}
server {
    listen [::]:80 default_server;
    listen 80 default_server;
    if ($host = h4o.dev) {
        return 301 https://www.$host$request_uri;
    } # managed by Certbot
    if ($host = www.h4o.dev) {
        return 301 https://$host$request_uri;
    } # managed by Certbot
    return 404; # managed by Certbot
}
```

In the `www.h4o.dev` server block, I use `root` entry to specify where my files are (the shared folder I created above), the `rewrite` is used to eliminate the trailing slash from the URL, and finally I use `try_files` to look for different files that can match the provided URL (as mentioned above, it looks for `URL/index.html` here). The `h4o.dev` & the http server block simply makes a 301 redirection.
