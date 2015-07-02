##Getting started with Telepat

There are two main ways you can get Telepat running on your infrastructure: using Docker containers or by cloning the source code off Github and running the NodeJS applications yourself.

##A. Docker containers

We provide official docker-compose recipes for running Telepat and its dependencies (Couchbase, Elasticsearch, Redis and Apache Kafka). The recipes are separated in two components, shared dependencies and the actual Telepat software. Once you have docker and docker-compose installed on your machine, here are the steps to get everything running:

    git clone https://github.com/telepat-io/telepat-docker-compose-files
    cd telepat-docker-compose-files/shared
    sudo docker-compose up 

Wait for things to boot up and when the logs stabilize, open a new terminal windows and start up the Telepat instance:

    cd telepat-docker-compose-files/telepat
    sudo docker-compose up

Right now everything should be up and running. The API instance is available on the same IP as your docker client (if you're running the Docker instance locally, it's localhost. If you're running on a Mac with boot2docker, you can find the IP by running boot2docker ip). The Sync API is running on port 3000 by default and the websockets endpoint runs on port 80 by default.

##B. From source

The Telepat backend stack is made up of two components. The Sync API (https://github.com/telepat-io/telepat-api) and the background workers (https://github.com/telepat-io/telepat-worker). Each of these repos provide usage instructions on their respective README files, generally it's a matter of setting the correct ENV variables for linking to Couchbase, Elasticsearch, Redis and Kafka and then starting the NodeJS apps.

Initial configuration

Along with the docker-compose recipes, the telepat-docker-compose-files repo also contains a bash script that can help seed initial data to your Telepat instance (stuff like creating an admin user and an initial app). While in the root folder of the cloned repo, run these two commands:

    chmod +x telepat.sh
    ./telepat.sh

You can then follow the on-screen instructions for running the various tasks.
