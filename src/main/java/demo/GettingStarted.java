package demo;

import org.apache.beam.sdk.Pipeline;
import org.apache.beam.sdk.io.TextIO;
import org.apache.beam.sdk.options.PipelineOptionsFactory;
import org.apache.beam.sdk.transforms.DoFn;
import org.apache.beam.sdk.transforms.GroupByKey;
import org.apache.beam.sdk.transforms.ParDo;
import org.apache.beam.sdk.transforms.Sum;
import org.apache.beam.sdk.transforms.ToString;
import org.apache.beam.sdk.values.PCollection;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class GettingStarted {
    private static final Logger LOG = LoggerFactory.getLogger(GettingStarted.class);

    static class ParseFn extends DoFn<String, GameActionInfo> {
        @ProcessElement
        public void processElement(ProcessContext context) {
            String userRecord = context.element(); // "user name, team name, score, timestamp millis"

            //context.output(new GameActionInfo(...));
        }
    }

    /**
     * Run a batch pipeline.
     */
    public static void main(String[] args) throws Exception {
        // Begin constructing a pipeline configured by commandline flags.
        BatchOptions options = PipelineOptionsFactory.fromArgs(args).withValidation().as(BatchOptions.class);
        Pipeline pipeline = Pipeline.create(options);
        LOG.info("pipeline options: " + options.toString());

        // Read events from a text file and parse them.
        PCollection<String> userRecords = pipeline.apply(TextIO.read().from(options.getInput()));

        // Parse the comma-separated values into a GameActionItem instance.
        // PCollection<GameActionInfo> parsedRecords = userRecords.apply(ParDo.of(new ParseFn))

        // Extract username/score pairs from the event data.

        // Sum the score for every user.

        // Format the results and write down to files.
        //PCollection<KV<String, Integer>, String> formattedPairs = finalScores.apply(ToString.kvs())

        // Write out the results
        // formattedRecords.apply(TextIO.write().to(options.getOutputPrefix()));

        // Run the batch pipeline.
        pipeline.run().waitUntilFinish();
    }
}
