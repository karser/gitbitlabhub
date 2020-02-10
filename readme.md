# GitBitLabHub: Mirror your repositories between Bitbucket / Gitlab / Github using simple webhooks.
- It's a simple shell script (written in pure bash, even the webserver part).
- The docker image is Alpine based and the size is about 10 MB.
- Single container mirrors a single repository.
- Single-threaded. It will ignore the next webhook while the previous one is being processed. DDoS protection out-of-the-box :). 

## Why mirror repositories?
- You can pipe multiple services. For example, use Bitbucket private repositories
  as a primary storage and self-hosted Gitlab instance as a purely CI/CD tool.
- Better safe than sorry. Mirroring repos is a single backup alternative for SaaS.

## How to use

### How to run using docker
```
docker run -it \
    -e SRC_REPO=git@bitbucket.org:vendor/src_repo.git \
    -e DEST_REPO=git@gitlab.example.com:2222/vendor/dest_repo.git \
    -e SRC_DEPLOY_KEY=base64_encoded_key \
    -e DEST_DEPLOY_KEY=base64_encoded_key \
    -p 8181:8080/tcp \
    karser/gitbitlabhub
```
where SRC_DEPLOY_KEY and DEST_DEPLOY_KEY can be obtained by running
```
base64 -w 0 < ~/.ssh/project_src_id_rsa
base64 -w 0 < ~/.ssh/project_dest_id_rsa
```

The URL will be http://localhost:8181

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
      SRC_DEPLOY_KEY: 'base64_encoded_key'
      DEST_DEPLOY_KEY: 'base64_encoded_key'
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

The URL will be https://gitbitlabhub.example.com/vendor/src_repo

## How to setup mirroring

1. Generate 2 deployment keys for source and destination:
```
ssh-keygen -t rsa -f ~/.ssh/project_src_id_rsa
ssh-keygen -t rsa -f ~/.ssh/project_dest_id_rsa
```
Add these keys to the repository settings of source and destination correspondingly.
```
cat ~/.ssh/project_src_id_rsa.pub
cat ~/.ssh/project_dest_id_rsa.pub
```
The Source deployment key can be marked as readonly. Depending on the platform it's called Deploy Token or Access key.
See how to add deployment/access keys to [bitbucket](https://bitbucket.org/blog/deployment-keys), [bitbucket access keys](https://confluence.atlassian.com/bitbucketserver/ssh-access-keys-for-system-use-776639781.html),
[gitlab](https://docs.gitlab.com/ce/ssh/), [github](https://developer.github.com/v3/guides/managing-deploy-keys/).

2. Run this container with all environment variables configured properly (see [How to use](#how-to-use) section).

3. Create the webhook in the source repository.
See how to create a webhook in [bitbucket](https://confluence.atlassian.com/bitbucket/manage-webhooks-735643732.html),
[gitlab](https://docs.gitlab.com/ce/user/project/integrations/webhooks.html), [github](https://developer.github.com/webhooks/creating/).


## How to build

```
docker build --tag karser/gitbitlabhub:latest .
docker push karser/gitbitlabhub:latest
```
