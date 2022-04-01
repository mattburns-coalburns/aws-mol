# Chapter 3. Provisioning a more robust EC2 website (WordPress!)


## Instructions
- Open a Terminal
- `cd chapters/ch3/`
- `terraform init`
- `terraform apply auto-approve`
- An SSH private key will be created in the current directory.
- Follow output instructions and connect to the EC2 instance via SSH. **NOTE:** You will have to be in the correct directory (`/aws-mol/chapters/ch3/`)
- Once you SSH to the instance, it may take a few moments for the LAMP stack to be WordPress to be installed. Give it 5 or so minutes.

### Configure Apache for WordPress
- Switch to root user: `sudo su -`
- Create Apache site for WordPress: `vim /etc/apache2/sites-available/wordpress.conf`
- Insert this block of code:
```
<VirtualHost *:80>
    DocumentRoot /srv/www/wordpress
    <Directory /srv/www/wordpress>
        Options FollowSymLinks
        AllowOverride Limit Options FileInfo
        DirectoryIndex index.php
        Require all granted
    </Directory>
    <Directory /srv/www/wordpress/wp-content>
        Options FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>
```
- Enable the site with: `a2ensite wordpress`
- Enable URL rewriting with: `a2enmod rewrite`
- Disable the default “It Works” site with: `sudo a2dissite 000-default`
- Finally, reload apache2 to apply all these changes: `service apache2 reload`

### Configure WordPress to connect to the database
- Now, let’s configure WordPress to use this database. First, copy the sample configuration file to wp-config.php: `sudo -u www-data cp /srv/www/wordpress/wp-config-sample.php /srv/www/wordpress/wp-config.php`
- Next, set the database credentials in the configuration file (do not replace database_name_here or username_here in the commands below. **NOTE:** For purposes of this lab, the default password for  is set to **ThisPhr@seIsNotEncrypted**: `sudo -u www-data sed -i 's/database_name_here/wordpress/' /srv/www/wordpress/wp-config.php && sudo -u www-data sed -i 's/username_here/wordpress/' /srv/www/wordpress/wp-config.php && sudo -u www-data sed -i 's/password_here/ThisPhr@seIsNotEncrypted/' /srv/www/wordpress/wp-config.php`
- Finally, in a terminal session open the configuration file in vim: `sudo -u www-data vim /srv/www/wordpress/wp-config.php`
- Find the following:
```
define( 'AUTH_KEY',         'put your unique phrase here' );
define( 'SECURE_AUTH_KEY',  'put your unique phrase here' );
define( 'LOGGED_IN_KEY',    'put your unique phrase here' );
define( 'NONCE_KEY',        'put your unique phrase here' );
define( 'AUTH_SALT',        'put your unique phrase here' );
define( 'SECURE_AUTH_SALT', 'put your unique phrase here' );
define( 'LOGGED_IN_SALT',   'put your unique phrase here' );
define( 'NONCE_SALT',       'put your unique phrase here' );
```
- Delete those lines, then replace with the content of https://api.wordpress.org/secret-key/1.1/salt/. (This address is a randomiser that returns completely random keys each time it is opened.) This step is important to ensure that your site is not vulnerable to “known secrets” attacks.
- Close and save (Press Esc, then colon (:), then type in `wq!`, and hit Enter)

### Configure WordPress
- Go back to where you ran the Terraform script, and naviagate to the web URL that was output.
- You should see the WordPress configuration. 
- You will be asked for title of your new site, username, password, and address e-mail. **NOTE:** the username and password you choose here are for WordPress, and do not provide access to any other part of your server - choose a username and password that are different to your MySQL (database) credentials, that we configured for WordPress’ use, and different to your credentials for logging into your computer or server’s desktop or shell.
- Now you can make your first post!

## Resources in this lab
- VPC
- Subnet
- Internet Gateway
- Route Table
- Security Groups
- EC2 Instance
- RSA 4096 Keys

## Additional Resources Used:
- https://ubuntu.com/tutorials/install-and-configure-wordpress