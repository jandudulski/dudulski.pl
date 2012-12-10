# The rule of thumb is to use 1 worker per processor core available,
# however since we'll be hosting many apps on this server,
# we need to take a less aggressive approach
worker_processes 2

# We deploy with capistrano, so "current" links to root dir of current release
working_directory "/var/www/dudulski.pl/current"

# Listen on unix socket
listen "/tmp/unicorn.dudulski.pl.sock", :backlog => 64

pid "/var/www/dudulski.pl/current/tmp/pids/unicorn.pid"

stderr_path "/var/www/dudulski.pl/current/log/unicorn.log"
stdout_path "/var/www/dudulski.pl/current/log/unicorn.log"
