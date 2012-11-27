Static-file provision:

[ ] Support hooks, i.e.:
    hooks:
      before:
        - cmd: mvn package
          cwd: anyone-web
          scope: local
      after:
        - cmd: unzip anyone-web.zip
          cwd: /srv/www/gethubble.com
          scope: remote
        
[ ] Add another wrapper for files:

    static:
      name:
        files:            # files to upload
          - ...
        hooks:            # before and after deploy hooks
          - ...
        services:         # assumes service with same name
          - restart


Maven:
[ ] Support hooks (?)

Conventions:
- Maven artifacts are deployed to `$path_prefix/$artifact_id`
- Services assume name: `$artifact_id`

Static-files:
- Are uploaded to `$path_prefix/$name`
- Services assume name: `$name`