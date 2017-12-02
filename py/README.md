# Apache Beam Workshop [Python Version]
This Readme file is for the Python version of the Apache Beam workshop.
Before starting, make sure to run the `setup.sh` script in the parent directory.

### Checking the results of your pipelines
If you use the provided `$GCP_OUTPUT_FILE` to output the results of your pipeline, you 
should be able to use `gsutil ls $GCP_OUTPUT_FILE` to see the results of your jobs, as
well as other file commands.


## Getting started pipeline
This file is for you to iterate over your solutions. You can use the Maven 
commands that we will use for other pipelines, except you'll just need to 
substitute the class to `-Dexec.mainClass="demo.GettingStarted"`.


## User scores pipeline

We have coded a mobile game, and it's become successful! We have millions of users around the world 
that are playing it multiple times per day. Whenever a user plays our game, they perform some
silly repetitive action, and score points. 

After every game, their score gets reported back to our data infrastructure, along with the
user name, team name, and a time stamp for when the user played that game.

We want to analyze this data. Initially, we'd like to create a pipeline that sums all the 
points obtained by every user individually; given that we are storing comma-separated
strings with their user name, team name, score, and timestamp.

Look at the code in `user_score.py`. To run this pipeline, use the following commands:

    python user_score.py --input $BEAM_LOCAL_FILE --output user_scores.txt

    python user_score.py --runner DataflowRunner \
                         --input $GCP_INPUT_FILE \
                         --output $GCP_OUTPUT_FILE/userscore/scores \
                         --project $GCP_PROJECT \
                         --temp_location $GCP_OUTPUT_FILE/tmp/


## Hourly team scores pipeline

Now, suppose that we want to step up our analytics. Instead of just adding up global scores,
suppose that we want to study how much each team performed every hour instead. This means that
we have to divide our data over two dimensions: by their timestamps, and by their team name.

The next pipeline is the one in `hourly_team_score.py`:

    python hourly_team_score.py --input $BEAM_LOCAL_FILE --output hourly_scores.txt

    python hourly_team_score.py --runner DataflowRunner \
                               --input $GCP_INPUT_FILE \
                               --output $GCP_OUTPUT_FILE/hourly/teamscore \
                               --project $GCP_PROJECT \
                               --temp_location $GCP_OUTPUT_FILE/tmp/


## Leader board pipeline
This pipeline is interesting because it's our first streaming pipeline. We want to keep an
up-to-date leaderboard so that it can be displayed on our website. We want to report the 
most up-to date results, but we also want to update them as time goes by and we get more
data.

Look at the code in `leader_board.py`.

    python leader_board.py  --topic projects/$GCP_PROJECT/topics/$PUBSUB_TOPIC --output leader_board_stream.txt

This pipeline does not work on Dataflow or other runners at the moment.
