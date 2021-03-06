# Ghost blog for Cloud Foundry

This repo is a fork of the lovely open source blogging engine [Ghost](https://github.com/TryGhost/Ghost) to make it easy to run on any Cloud Foundry.

For example, we run Ghost at https://www.starkandwayne.com/blog, https://www.starkandwayne.com/videos and https://www.dingotiles.com/blog using this repository.

The modifications in this repository - versus the upstream https://github.com/TryGhost/Ghost - are:

* `config.js` that loads PostgreSQL from the `$VCAP_SERVICES` provided by Cloud Foundry (see below for setup) - used for storing blog posts
* `config.js` that loads AWS S3 credentials from `$VCAP_SERVICES` - used for storing uploaded images from authors
* `config.js` that looks for email credentials from `$VCAP_SERVICES` - used for sending invitation emails, password resets etc.
* custom themes for https://www.starkandwayne.com/blog and https://www.dingotiles.com/blog, in addition to the default upstream Casper theme

This repository also includes the Concourse pipeline `ci/pipeline.yml` for automatically attempting to upgrade to any new version of Ghost (https://github.com/TryGhost/Ghost/releases). We are running this pipeline at https://ci.vsphere.starkandwayne.com/teams/main/pipelines/ghost-for-cloudfoundry

## Deploy to Cloud Foundry

First, target your Cloud Foundry and create a space for deploying the application and its dependent service instances:

```
cf login -a https://api.run.pivotal.io
cf create-space blog-production
cf target -s blog-production
```

Next, provision three service instances:

* PostgreSQL
* Email
* AWS S3

For Pivotal Web Services, as an example, you might choose ElephantSQL for PostgreSQL, SendGrid for email, and a custom user-provided service instance for your AWS S3 account.

```
cf create-service elephantsql turtle blog-pg
cf create-service sendgrid free blog-email
cf create-user-provided-service blog-s3 -p '{"access_key_id":"AKIAI74XXXX","secret_access_key":"rXuScFqhvqXXXXX","bucket":"BUCKETNAME","region":"us-east-1"}'
```

Next, deploy/push the Ghost application without starting it, bind the three services to it, and then restart:

```
cf push --no-start --random-route
cf bs ghost blog-pg
cf bs ghost blog-email
cf bs ghost blog-s3
cf restart ghost
```

In another terminal window you can observe the Ghost logs using:

```
cf logs ghost
```

The last line of the logs will include the URL:

```
2017-01-23T11:41:40.84+1000 [APP/PROC/WEB/0]OUT Ghost is running in production...
2017-01-23T11:41:40.84+1000 [APP/PROC/WEB/0]OUT Your blog is now available on http://ghost-villalike-mee.cfapps.io
```

From Cloud Foundry's perspective, the Ghost blog is a Node.js web application. It will automatically select a secure version of Node.js and package manager, then download all the Node.js dependencies (see `package.json`). Using Cloud Foundry it is as lovely to run web applications as it is to write blog posts on Ghost.

The `--random-route` flag above is optional. You can bind any route to your Cloud Foundry application.

For example, we have Ghost running on Pivotal Web Services, and we bound https://www.starkandwayne.com/blog to this application. The command we used to do this was:

```
cf map-route ghost starkandwayne.com --hostname www --path blog
```

Go to the `/ghost` end point to setup your blog, create your initial author/admin user, and invite other people to become authors on your blog.

## Deploy using Dingo PostgreSQL

We are the authors and maintainers of Dingo PostgreSQL - a batteries-included PostgreSQL as a service for any Cloud Foundry installation. It is available as a [Pivotal tile](https://network.pivotal.io/products/dingo-postgresql-for-pcf).

To provision a highly-available, continuously archiving PostgreSQL database via Dingo PostgreSQL (after it has been installed by your platform ops team):

```
cf create-service dingo-postgresql cluster blog-pg
```

It may take a minute or two to start up the two-node cluster and finish its initial base backup. Poll for completion status using:

```
cf service blog-pg
```

### Why Dingo PostgreSQL?

We use Dingo PostgreSQL at Stark & Wayne as the backend for our own blog and other internal applications. One day we were forced to use its disaster recovery system on our real live data. It worked. Our blog, and other databases, were recreated and recovered successfully.
