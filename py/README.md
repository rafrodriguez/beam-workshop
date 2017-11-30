# Apache Beam Workshop [Python Version]
This Readme file is for the Python version of the Apache Beam workshop.


## User scores pipeline
The first pipeline is the one defined in `user_score.py`. To run this pipeline using the direct
runner use the following command:

    python user_score.py --input $BEAM_LOCAL_FILE --output user_scores.txt

    python user_score.py --runner DataflowRunner \
                         --input $GCP_INPUT_FILE \
                         --output $GCP_OUTPUT_FILE/userscore/scores \
                         --project $GCP_PROJECT \
                         --temp_location $GCP_OUTPUT_FILE/tmp/


## Hourly team scores pipeline
The next pipeline is the one in `hourly_team_score.py`:

    python hourly_team_score.py --input $BEAM_LOCAL_FILE --output hourly_scores.txt

    python hourly_team_score.py --runner DataflowRunner \
                               --input $GCP_INPUT_FILE \
                               --output $GCP_OUTPUT_FILE/hourly/teamscore \
                               --project $GCP_PROJECT \
                               --temp_location $GCP_OUTPUT_FILE/tmp/


## Leader board pipeline
The next pipeline is the one in `leader_board.py`. This pipeline is interesting because it is not just
a windowed batch pipeline. In fact, it is a full streaming pipeline - and it is able to

    python leader_board.py  --topic projects/$GCP_PROJECT/topics/$PUBSUB_TOPIC --output leader_board_stream.txt

This pipeline does not yet work on Dataflow or other runners at the moment.