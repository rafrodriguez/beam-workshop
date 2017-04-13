# Apache Beam Portability Demo

For all runners, batch demo shows:
* Graph structure 
* Proof of parallelism
* Input data size
* Metric: parseErrors

Streaming demo adds:
* Watermarks

## Injector

On a new "injector VM", install Maven (minimum 3.3.1), git, and OpenJDK 7.

    git clone https://github.com/davorbonaci/beam-portability-demo.git
    cd beam-portability-demo

    screen
    mvn clean compile exec:java@injector

Press `Ctrl-A`, `Ctrl-D` (later `screen -r` to resume).

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

To view the Apache Flink UI, in another terminal:

    gcloud compute ssh --zone=us-central1-f --ssh-flag="-D 1081" --ssh-flag="-N" --ssh-flag="-n" gaming-flink-m

Launch magic Google Chrome window and, if applicable, set BeyondCorp to
System/Alternative:

    /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
      --proxy-server="socks5://localhost:1081" \
      --host-resolver-rules="MAP * 0.0.0.0 , EXCLUDE localhost" \
      --user-data-dir=/tmp/

Open the UI:

    http://gaming-flink-m:8088/

In the Flink UI, capture values of `jobmanager.rpc.address` and
`jobmanager.rpc.port` in the Job Manager configuration.

In another terminal, set up an SSH tunnel to the machine in the cluster running
the Flink Job Manager:

    gcloud compute ssh gaming-flink-w-6 --zone us-central1-f --ssh-flag="-D 1082"

Build the package and stage it in Google Cloud Storage:

    mvn clean package exec:java -Pflink-runner \
        -DsocksProxyHost=localhost \
        -DsocksProxyPort=1082 \
        -Dexec.mainClass="demo.HourlyTeamScore" \
        -Dexec.args="--runner=flink \
                     --input=gs://apache-beam-demo/data/gaming* \
                     --outputPrefix=gs://apache-beam-demo-davor/flink/hourly/scores \
                     --filesToStage=target/portability-demo-bundled-flink.jar \
                     --flinkMaster=gaming-flink-w-6.c.apache-beam-demo.internal:52871"

## Apache Spark cluster in Google Cloud Dataproc

    gcloud dataproc clusters create gaming-spark \
        --image-version=1.0 \
        --zone=us-central1-f \
        --num-workers=25 \
        --worker-machine-type=n1-standard-8 \
        --master-machine-type=n1-standard-8 \
        --worker-boot-disk-size=100gb \
        --master-boot-disk-size=100gb

To view the Apache Spark UI, in another terminal:

    gcloud compute ssh --zone=us-central1-f --ssh-flag="-D 1080" --ssh-flag="-N" --ssh-flag="-n" gaming-spark-m

Launch magic Google Chrome window and, if applicable, set BeyondCorp to
System/Alternative:

    /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
        --proxy-server="socks5://localhost:1080" \
        --host-resolver-rules="MAP * 0.0.0.0 , EXCLUDE localhost" \
        --user-data-dir=/tmp/

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
        --outputPrefix=gs://apache-beam-demo-davor/spark/hourly/scores \
        --input=gs://apache-beam-demo/data/gaming*
