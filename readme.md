# GitBitLabHub: Mirror your repositories between Bitbucket / Gitlab / Github using simple webhooks.
<a href="https://hub.docker.com/r/karser/gitbitlabhub">![Docker Pulls](https://img.shields.io/docker/pulls/karser/gitbitlabhub)</a>

- It's a simple shell script (written in pure bash, even the webserver part).
- The docker image is Alpine based and the size is about 10 MB.
- Single container mirrors a single repository.

## Why mirror repositories?
- You can pipe multiple platforms. For example, use Bitbucket private repositories
  as a primary storage and self-hosted Gitlab instance as a purely CI/CD tool.
- Backup your primary repository to another platform.

## How to setup mirroring

1. Generate an ssh key for source and destination repositories:
```
ssh-keygen -t rsa -f ~/.ssh/project_id_rsa
```
- It will generate 2 keys, the PRIVATE key to ~/.ssh/project_id_rsa and the PUBLIC key to ~/.ssh/project_id_rsa.pub.
- The PUBLIC key is used as Deploy Key while the PRIVATE key should be used in SRC_DEPLOY_KEY and DEST_DEPLOY_KEY env variables.

2. Add this PUBLIC key as a Deploy Key for the source and destination repositories.
   Depending on the platform it's called Deploy Key or Access key.
   See how to add Deploy/Access Key to [bitbucket](https://bitbucket.org/blog/deployment-keys), [bitbucket access keys](https://confluence.atlassian.com/bitbucketserver/ssh-access-keys-for-system-use-776639781.html),
   [gitlab](https://docs.gitlab.com/ee/user/project/deploy_keys/index.html), [github](https://docs.github.com/en/developers/overview/managing-deploy-keys#deploy-keys).
- Add the PUBLIC key to the source repo with **read-only** access.
- Add the PUBLIC key to the destination repo with **write** access.

3. Run this container in docker with all environment variables configured properly (see [How to run](#how-to-run) section).
- Use the PRIVATE key for SRC_DEPLOY_KEY and DEST_DEPLOY_KEY env variables. Don't forget to encode it with base64:
  `base64 -w 0 < ~/.ssh/project_id_rsa`
- If you configured everything properly it should mirror the repo after the first launch. If it didn't see the logs in the container output.

4. Create the webhook in the source repository. Using default settings should be enough.
   See how to create a webhook in [bitbucket](https://confluence.atlassian.com/bitbucket/manage-webhooks-735643732.html),
   [gitlab](https://docs.gitlab.com/ce/user/project/integrations/webhooks.html), [github](https://docs.github.com/en/developers/webhooks-and-events/webhooks/creating-webhooks#setting-up-a-webhook).

## How to run

### How to run using docker
```
docker run -it \
    -e SRC_REPO=git@bitbucket.org:vendor/src_repo.git \
    -e DEST_REPO=git@gitlab.example.com:2222/vendor/dest_repo.git \
    -e SRC_DEPLOY_KEY=base64_encoded_key== \
    -e DEST_DEPLOY_KEY=base64_encoded_key== \
    -p 8181:8080/tcp \
    karser/gitbitlabhub
```
Where SRC_DEPLOY_KEY and DEST_DEPLOY_KEY are PRIVATE ssh keys encoded with base64.
You can use the same key for both though. It can be obtained by running
```
ssh-keygen -t rsa -f ~/.ssh/project_id_rsa
base64 -w 0 < ~/.ssh/project_id_rsa
```

With this configuration the webhook url will be http://localhost:8181

### How to run using docker-compose and traefik

```
version: '3.3'

services:
  gitbitlabhub_repo1:
    image: karser/gitbitlabhub
    restart: always
    networks:
      - webproxy
    environment:
      SRC_REPO: 'git@bitbucket.org:vendor/src_repo.git'
      DEST_REPO: 'git@gitlab.example.com:2222/vendor/dest_repo.git'
      SRC_DEPLOY_KEY: 'base64_encoded_key=='
      DEST_DEPLOY_KEY: 'base64_encoded_key=='
    labels:
      - "traefik.enable=true"
      - "traefik.backend=gitbitlabhub_repo1"
      - "traefik.frontend.rule=Host:gitbitlabhub.example.com;PathPrefixStrip:/vendor/src_repo"
      - "traefik.port=8080"
      - "traefik.docker.network=webproxy"
    volumes:
      - ./gitbitlabhub:/storage

networks:
  webproxy:
    external: true
```
With this configuration the webhook url will be https://gitbitlabhub.example.com/vendor/src_repo

## Known issues:

- It will ignore a webhook if it is still processing the previous one. As a rule of thumb, wait 5-10 seconds between `git push` runs.

## How to build

```
docker build --tag karser/gitbitlabhub:latest .
docker push karser/gitbitlabhub:latest
```
