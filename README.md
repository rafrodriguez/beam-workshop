# Apache Beam Workshop
This is a full course that should help you immerse yourself in Apache Beam.
Through this workshop, we will review Batch and Streaming concepts, and apply
them to build some data analytics pipelines.

For this, you will need the following:
* A Github account, to clone this repository
* A setup for some Beam runner:
  * A Spark Cluster
  * A Flink Cluster
  * A GCP Project with Dataflow enabled
  * The Beam Direct runner
* It's desirable, but not necessary, to have familiarity with the high-level
  concepts of distributed data processing.

### Java / Python / Runners
This workshop is mainly geared for Java, so you can run the exercises in
different runners. Nonetheless, also Python examples are provided.

## Getting started
First of all, you'll need to set up the basic environment variables that you
will use to submit jobs to different clusters, and sources. Run:

    source setup.sh

Normally the default values will be enough, but check with the instructor to make
sure that you get all the proper variables.

### Requirements
You will need to have Maven 3.3.1+, and JDK 7+ installed. To install them:

* OpenJDK http://openjdk.java.net/install/
* Maven [Download: https://maven.apache.org/download.cgi, Install: https://maven.apache.org/install.html]
* Git   https://git-scm.com/book/en/v2/Getting-Started-Installing-Git

## Running pipeline


    mvn clean package exec:java -Pdirect-runner \
        -Dexec.mainClass="demo.UserScore" \
        -Dexec.args="--runner=DirectRunner --input=data/demo-file.csv --output=data/outputfiles"

    mvn clean package exec:java -Pdataflow-runner \
        -Dexec.mainClass="demo.UserScore" \
        -Dexec.args="--runner=DataflowRunner \
                     --input=$GCP_INPUT_FILE \
                     --output=$GCP_OUTPUT_FILE \
                     --project=$GCP_PROJECT"

    mvn clean package exec:java -Pflink-runner \
        -Dexec.mainClass="demo.UserScore" \
        -Dexec.args="--runner=flink \
                     --input=$GCP_INPUT_FILE \
                     --output=$GCP_OUTPUT_FILE \
                     --filesToStage=target/portability-demo-bundled-flink.jar \
                     --flinkMaster=$FLINK_MASTER_ADDRESS"






For all runners, batch demo shows:
* Graph structure 
* Proof of parallelism
* Input data size
* Metric: parseErrors

Streaming demo adds:
* Watermarks


## Injector

On a new "injector VM", install Maven (minimum 3.3.1), git, and OpenJDK 7. The
injector can inject data to a Kafka Topic, a Pubsub Topic, or a local file. To
test your own changes, you can generate a local file with data:

    mvn clean compile exec:java@injector -Dexec.args="--fileName=$BEAM_LOCAL_FILE"

Press `Ctrl-C` when you are pleased with the amount of data generated.

To stream data to PubSub, use the flags `--gcpProject=$GCP_PROJECT --pubsubTopic=$PUBSUB_TOPIC` instead of `--fileName`.
To stream data to Kafka, you may run the Injector without any arguments.

## Google Cloud Dataflow

HourlyTeamScore:

    mvn clean compile exec:java@HourlyTeamScore-Dataflow -Pdataflow-runner

Leaderboard (requires the injector):

    mvn clean compile exec:java@LeaderBoard-Dataflow -Pdataflow-runner

## Apache Flink cluster in Google Cloud Dataproc

    gsutil cp dataproc-config/dataproc-flink-init.sh gs://apache-beam-demo/config/

    gcloud dataproc clusters create gaming-flink \
        --zone=us-central1-f \
        --initialization-actions gs://apache-beam-demo/config/dataproc-flink-init.sh \
        --initialization-action-timeout 5m \
        --num-workers=20 \
        --scopes=https://www.googleapis.com/auth/cloud-platform \
        --worker-boot-disk-size=100gb \
        --master-boot-disk-size=100gb

Open the UI:

    http://gaming-flink-m:8088/

In the Flink UI, capture values of `jobmanager.rpc.address` (i.e. gaming-flink-w-5) and
`jobmanager.rpc.port` (i.e. 58268) in the Job Manager configuration.

In separate terminals, use those two values to set up two SSH tunnels to the machine in the cluster
running the Flink Job Manager:

    gcloud compute ssh gaming-flink-w-10 --zone us-central1-f --ssh-flag="-D 1082"

    gcloud compute ssh gaming-flink-w-10 --zone us-central1-f --ssh-flag="-L 40007:localhost:40007"

Submit HourlyTeamScore to the cluster:

    mvn clean package exec:java -Pflink-runner \
        -DsocksProxyHost=localhost \
        -DsocksProxyPort=1082 \
        -Dexec.mainClass="demo.HourlyTeamScore" \
        -Dexec.args="--runner=flink \
                     --input=gs://apache-beam-demo/data/gaming* \
                     --outputPrefix=gs://apache-beam-demo-fjp/flink/hourly/scores \
                     --filesToStage=target/portability-demo-bundled-flink.jar \
                     --flinkMaster=gaming-flink-w-10.c.apache-beam-demo.internal:40007"

Submit LeaderBoard to the cluster:

    mvn clean package exec:java -Pflink-runner \
        -DsocksProxyHost=localhost \
        -DsocksProxyPort=1082 \
        -Dexec.mainClass="demo.LeaderBoard" \
        -Dexec.args="--runner=flink \
                     --kafkaBootstrapServer=35.184.132.47:9092 \
                     --topic=game \
                     --outputPrefix=gs://apache-beam-demo-fjp/flink/leader/scores \
                     --filesToStage=target/portability-demo-bundled-flink.jar \
                     --flinkMaster=gaming-flink-w-10.c.apache-beam-demo.internal:40007"

If you receive an error saying `Cannot resolve the JobManager hostname`, you
may need to modify your `/etc/hosts` file to include an entry like this:

    127.0.0.1 gaming-flink-w-5.c.apache-beam-demo.internal

## Apache Spark cluster in Google Cloud Dataproc

    gcloud dataproc clusters create gaming-spark \
        --image-version=1.0 \
        --zone=us-central1-f \
        --num-workers=25 \
        --worker-machine-type=n1-standard-8 \
        --master-machine-type=n1-standard-8 \
        --worker-boot-disk-size=100gb \
        --master-boot-disk-size=100gb

Open the UI:

    http://gaming-spark-m:18080/

Submit the job to the cluster:

    mvn clean package -Pspark-runner

    gcloud dataproc jobs submit spark \
        --cluster gaming-spark \
        --properties spark.default.parallelism=200 \
        --class demo.HourlyTeamScore \
        --jars ./target/portability-demo-bundled-spark.jar \
        -- \
        --runner=spark \
        --outputPrefix=gs://apache-beam-demo-fjp/spark/hourly/scores \
        --input=gs://apache-beam-demo/data/gaming*


# Extras

## Apache Kafka cluster in Google Cloud Dataproc

Set firewall rules for your GCP project to open `tcp:2181, tcp:2888, tcp:3888` for Zookeeper and `tcp:9092` for Kafka.

Start the Kafka cluster:

    gcloud dataproc clusters create kafka \
        --zone=us-central1-f \
        --project=$GCP_PROJECT \
        --initialization-actions gs://apache-beam-demo/config/dataproc-kafka-init.sh \
        --initialization-action-timeout 5m \
        --num-workers=3 \
        --scopes=https://www.googleapis.com/auth/cloud-platform \
        --worker-boot-disk-size=100gb \
        --master-boot-disk-size=500gb \
        --master-machine-type n1-standard-4 \
        --worker-machine-type n1-standard-4       

Create a topic to use for the game:

    bin/kafka-topics.sh --create --zookeeper $KAFKA_ADDRESS --replication-factor 1 --partitions 3 --topic game

Note: The project `pom.xml` currently hard codes the external IP address for `kafka-m`, so you'll need to edit it by hand.

