# Pushwagner [![Build Status](https://secure.travis-ci.org/oc/pushwagner.png)](http://travis-ci.org/oc/pushwagner)

[X] Release early, [ ] Release often

## Document config

Pushwagner searches for a config in: `./deploy.yml`, `./.pw.yml`, and `./config/deploy.yml`.

Pushwagner is currently extremely opinionated to my usual practises.

Some conventions:
- Prefer ssh key-based deployment (Use reallly strong SSH-keys with your own ssh-agent or not at your own peril)
- Place most shit in /var/www|lib|keke/<app>, logs in /var/log, cfg in /etc/<app>. 
- Let your app orchestration service or dscm set up access to deployers (I use salt|ansible|puppet for both app orchestration and dscm/infrastructure cfg) f.x.: NOPASSWD `sudo service svcname <start|restart|stop>`
- I usually separate application infrastructrure config (in infrastructure/app orchestration) and app config (toggles, etc)
- I usually thus create service wrappers / systemd / upstart shit with said dscm

### Minimal configuration

````yaml
# Must set a default path for file uploads
path_prefix: /var/apps

# Must specify a default environment.
environments:
  default:
    hosts: [test.example.com]
````

### Environments

````yaml
path_prefix: /var/apps

# Must specify a default environment.
environments:
  test: &test
    hosts: [test.example.com]
    user: testuser
  production: &production
    hosts: [a1.example.com, a2.example.com]
    user: productionuser
  default: 
    <<: *production

````


### Maven (M2) repo integration

````yaml
# required
path_prefix: /var/apps

maven:
  repositories:
    releases:  http://repo.example.com/nexus/content/repositories/releases
    snapshots: http://repo.example.com/nexus/content/repositories/snapshots
  artifacts:
    # creates /var/apps/foo/foo-webapp.jar by default (assumes foo-webapp is a jar)
    # I guess I should read the pom packaging some day... Or you can pull req it.
    foo:
      group_id:    com.example
      artifact_id: foo-webapp
      version:     1.0-SNAPSHOT
````

### Static file uploads

````yaml
path_prefix: /var/apps

static:
  /var/log/foo:
    - app.log
  static:
  	- file.txt
  	- folder/
  /usr/lib/foo:
    # Globbing support
  	- src/*{[!.git/]*}
````

### Hooks

before & after, both local & remote.

Sudo support, automatically prompts for passwd, or use: `env PUSHWAGNER_SUDO=sudopasswd`.

````yaml
hooks:
	local:
		before:
			- mvn package
		after:
			- mvn test -Pint
	remote:
		before:
			- /usr/sbin/service foo stop
		after:
			- /usr/sbin/service foo start
````

### Environments

````yaml
environments:
  test: &test
    hosts: [test.example.com]
    user:  testuser
  production: &production
      hosts: [production.example.com]
      user:  www-data
  default:
    <<: *test
````


## Build & deploy:

bump lib/pushwagner/version.rb
gem build pushwagner.gemspec
gem push pushwagner-x.x.x.x.gem
