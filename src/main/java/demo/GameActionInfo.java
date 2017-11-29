package demo;

import org.apache.avro.reflect.Nullable;
import org.apache.beam.sdk.coders.AvroCoder;
import org.apache.beam.sdk.coders.DefaultCoder;

/**
 * Class to hold info about a game event.
 */
@DefaultCoder(AvroCoder.class)
public class GameActionInfo {
  @Nullable
  String user;
  @Nullable String team;
  @Nullable Integer score;
  @Nullable Long timestamp;

  public GameActionInfo() {}

  public GameActionInfo(String user, String team, Integer score, Long timestamp) {
    this.user = user;
    this.team = team;
    this.score = score;
    this.timestamp = timestamp;
  }

  public String getUser() {
    return this.user;
  }
  public String getTeam() {
    return this.team;
  }
  public Integer getScore() {
    return this.score;
  }
  public Long getTimestamp() {
    return this.timestamp;
  }
}