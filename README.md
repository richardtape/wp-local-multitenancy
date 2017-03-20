# WordPress Local Multitenancy

This is super, super ugly and dirty at the moment, but it does the trick. (Mac only)

A couple of shell scripts which allow you to have your own local multi-tenancy solution.

## Requirements

wp-cli installed and available as 'wp' from within a shell
nginx and mysql installed (probably via brew)
2 nginx config files (php-fpm and wp-generic in certain places)

## What doesn't this do (yet)?

- ~~Create a database on your local machine.~~ UPDATE: It tries to, now. It might not ALWAYS work with some setups.
- ~~Restart nginx after all is said and done~~ UPDATE: Again, tries to. Will need sudo password so you may be prompted.
- Make you a cup of coffee (so that probably means @norcross is out)

## What DOES this do?

Quite a lot, actually.

`newwp.sh` adds a new version of WordPress to the ./wordpress/ directory (you'll need to create this the first time)

`newsite.sh` sets up a new site locally by;

- Creating the requisite directories and symlinks
- Generates a site-specific wp-config.php file based on answers to questions your are prompted, and using wp-cli
- Generates a site-specific SSL certificate allowing you to use SSL locally (you'll need to manually accept this in Keychain Access)
- Adds a site-specific nginx configuration file

## Usage

Clone this repo locally.

You'll notice that in ./wordpress/ there's a symlink which points to 4.7.2 - that won't exist for you, yet.

Run `./newwp.sh -v 4.7.2` which uses wp-cli to download WordPress version 4.7.2 and place it into ./wordpress/4.7.2/

Your `stable` symlink will now work. (and should you wish to test with other versions of WordPress, you can, by repeating the above with a different version number and then altering the symlink or choosing to make it live when prompted)

You may wish to edit the shared/nginx-site-template.conf file to suit your needs. For me, I have a `php-fpm` file which contains

```
location ~ \.php$ {
    try_files      $uri = 404;
    fastcgi_pass   127.0.0.1:1523;
    fastcgi_index  index.php;
    fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include        fastcgi_params;
}
```

and a `wp-generic` file which contains

```
# Common rules for all WP sites
location / {
    try_files $uri $uri/ /index.php?$args;
}

# Add trailing slash to */wp-admin requests.
rewrite /wp-admin$ $scheme://$host$uri/ permanent;

# Remove need for /wp/
rewrite ^(/[^/]+)?(/wp-.*) /wp$2 last;
```

Now you're pretty much all set up. You can start creating sites with

`./newsite.sh`

And you'll be prompted for domains, usernames and passwords.

You should then end up with a new directory on the same level as the shell scripts such as domain.com which contains an index.php (copied from ./shared), a wp-config.php that is created for you, a content directory which is where all your plugins, themes and mu-plugins can go, as well as a symlink for the WordPress core files which points to ./wordpress/stable (which for you, now, will point to ./wordpress/4.7.2/).

Assuming you chose domain.dev as your local domain when prompted, Keychain Access will be opened and you'll need to accept the generated SSL cert.

Now if you visit http://domain.dev/ (or https should you need it) you'll see the WordPress install screen. You're good to go!

You can specify the location of your nginx config files by adding a -n flag, i.e. ./newsite.sh -n /path/to/nginx/config/ -- by default it is /usr/local/etc/nginx/sites-enabled because that's where it is on my system (where brew put it)

This also assumes you have a `include /usr/local/etc/nginx/sites-enabled/*;` within your main `http` block in your main `nginx.conf` file

## Notes

This is kinda specific right now. But I'm hoping that it will help others and eventually it can be made more generic. It desperately needs some requirement checking and probably some more flexibility. I believe having nginx and mysql installed natively on your machine is the best way forward, rather than using MAMP or VVV or the-like. Products like that are amazing - genuinely - but if they fail, they're devilishly difficult to debug.

Also, probably, with some hardening and after being made more generic, this could be used on a production site after swapping out the SSL generation stuff with Lets Encrypt.

## TODO

1. Use ansible to provision the local setup (nginx, mysql) to make provisioning easier
2. Use ansible to provision staging/production environments to match and...
3. Once (2.) is complete, have a way to deploy from local to staging/prod and vice-versa
