# Pushwagner [![Build Status](https://secure.travis-ci.org/oc/pushwagner.png)](http://travis-ci.org/oc/pushwagner)

[X] Release early, [ ] Release often

## Document config

Pushwagner searches for a config in: `./deploy.yml`, `./.pw.yml`, and `./config/deploy.yml`.

Pushwagner is currently extremely opinionated to my usual practises.

### Minimal configuration

````yaml
# Must set a default path for file uploads
path_prefix: /var/apps

# Must specify a default environment.
environments:
  default:
    hosts: [test.example.com]
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
  	# creates /var/apps/foo.jar by default (assumes foo-webapp is a jar for now)
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
			- mvn test -Pintegrationtests
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
