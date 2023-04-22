FROM hshar/webapp

# Set the working directory to /var/www/html
WORKDIR /var/www/html

# Copy the source code into the container
COPY . .

# Expose port 80 for HTTP traffic
EXPOSE 80

# Start Apache web server when the container starts
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]