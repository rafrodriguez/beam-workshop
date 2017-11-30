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
different runners. 

Python examples are also provided, though these only work on the 
Direct runner and the Dataflow runner. Check out the `py/` directory
and its `README` for the Python code.

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

## The UserScore pipeline

    mvn clean package exec:java -Pdirect-runner \
        -Dexec.mainClass="demo.UserScore" \
        -Dexec.args="--runner=DirectRunner --input=$BEAM_LOCAL_FILE --outputPrefix=data/outputfiles"
        
    mvn clean package exec:java -Pdataflow-runner \
        -Dexec.mainClass="demo.UserScore" \
        -Dexec.args="--runner=DataflowRunner \
                     --input=$GCP_INPUT_FILE \
                     --outputPrefix=$GCP_OUTPUT_FILE/dataflow/user/res \
                     --project=$GCP_PROJECT"
                     
    mvn clean package -Pspark-runner
    gcloud dataproc jobs submit spark \
            --project=$GCP_PROJECT \
            --cluster gaming-spark \
            --properties spark.default.parallelism=200 \
            --class demo.UserScore \
            --jars ./target/portability-demo-bundled-spark.jar \
            -- \
            --runner=spark \
            --input=$GCP_INPUT_FILE \
            --outputPrefix=$GCP_OUTPUT_FILE/spark/user/res

    mvn clean package exec:java -Pflink-runner \
        -Dexec.mainClass="demo.UserScore" \
        -Dexec.args="--runner=flink \
                     --input=$GCP_INPUT_FILE \
                     --outputPrefix=$GCP_OUTPUT_FILE/flink/user/res \
                     --filesToStage=target/portability-demo-bundled-flink.jar \
                     --flinkMaster=$FLINK_MASTER_ADDRESS \
                     --parallelism=20"

## The HourlyTeamScore pipeline

    mvn clean package exec:java -Pdirect-runner \
             -Dexec.mainClass="demo.HourlyTeamScore" \
             -Dexec.args="--runner=DirectRunner --input=$BEAM_LOCAL_FILE --outputPrefix=data/count"

    mvn clean package exec:java -Pdataflow-runner \
            -Dexec.mainClass="demo.HourlyTeamScore" \
            -Dexec.args="--runner=DataflowRunner \
                         --input=$GCP_INPUT_FILE \
                         --outputPrefix=$GCP_OUTPUT_FILE/dataflow/hourly/res \
                         --project=$GCP_PROJECT"

     mvn clean package -Pspark-runner
     gcloud dataproc jobs submit spark \
            --project=$GCP_PROJECT \
            --cluster gaming-spark \
            --properties spark.default.parallelism=200 \
            --class demo.HourlyTeamScore \
            --jars ./target/portability-demo-bundled-spark.jar \
            -- \
            --runner=spark \
            --input=$GCP_INPUT_FILE \
            --outputPrefix=$GCP_OUTPUT_FILE/spark/hourly/res

        mvn clean package exec:java -Pflink-runner \
            -Dexec.mainClass="demo.HourlyTeamScore" \
            -Dexec.args="--runner=flink \
                         --input=$GCP_INPUT_FILE \
                         --outputPrefix=$GCP_OUTPUT_FILE/flink/hourly/res \
                         --filesToStage=target/portability-demo-bundled-flink.jar \
                         --flinkMaster=$FLINK_MASTER_ADDRESS \
                         --parallelism=20"

## The LeaderBoard pipeline
This pipeline is interesting because it's our first streaming pipeline

    mvn clean package exec:java -Pdirect-runner \
            -Dexec.mainClass="demo.LeaderBoard" \
            -Dexec.args="--runner=DirectRunner \
                         --topic=projects/$GCP_PROJECT/topics/$PUBSUB_TOPIC \
                         --outputPrefix=data/outputfiles"

    mvn clean package exec:java -Pdataflow-runner \
            -Dexec.mainClass="demo.LeaderBoard" \
            -Dexec.args="--runner=DataflowRunner \
                         --topic=projects/$GCP_PROJECT/topics/$PUBSUB_TOPIC \
                         --outputPrefix=$GCP_OUTPUT_FILE/dataflow/leader/res"

    mvn clean package exec:java -Pflink-runner \
                -Dexec.mainClass="demo.LeaderBoard" \
                -Dexec.args="--runner=flink \
                             --topic=projects/$GCP_PROJECT/topics/$PUBSUB_TOPIC \
                             --outputPrefix=$GCP_OUTPUT_FILE/flink/leader/res \
                             --parallelism=20"







## Injector

On a new "injector VM", install Maven (minimum 3.3.1), git, and OpenJDK 7. The
injector can inject data to a Kafka Topic, a Pubsub Topic, or a local file. To
test your own changes, you can generate a local file with data:

    mvn clean compile exec:java@injector -Dexec.args="--fileName=$BEAM_LOCAL_FILE"

Press `Ctrl-C` when you are pleased with the amount of data generated.

To stream data to PubSub, use the flags `--gcpProject=$GCP_PROJECT --pubsubTopic=$PUBSUB_TOPIC` instead of `--fileName`.
To stream data to Kafka, you may run the Injector without any arguments.

##  Flink errors
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
