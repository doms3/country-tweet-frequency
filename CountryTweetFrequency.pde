import twitter4j.*;
import twitter4j.conf.*;

import java.util.*;

import org.gicentre.geomap.*;
import org.gicentre.geomap.io.*;

// Definitions
GeoMap geoMap;
TwitterStream twitter;

// Counts are displayed later for sanity's sake
int tweetsChecked = 0;
int countriesFound = 0;

// Import should be of size 241 but 250 chosen for extra buffer

// Maps the given country to it search terms
Map< String, List<String> > searchMap = new HashMap( 250 );

// Maps the given country to the tweet that mention it
Map< String, List<String> >  tweetMap = new HashMap( 250 );

void setup() {
  background(202, 226, 245);  // Ocean colour
  stroke(0, 40); // Border colour
  size(1200, 600); 

  geoMap = new GeoMap( this );  // Create the geoMap object.
  geoMap.readFile( "assets/world" );   // Read shapefile.  

  Table rawData = loadTable( "assets/countries.txt", "tsv" ); // Load countries, format should be " Country Name + "\t" + Search Term + ", " + Search Term .... "
  
  for ( TableRow row : rawData.rows() ) {
    String country = row.getString( 0 ); // Get countries
    String[] searchTerms = row.getString( 1 ).split( ", " ); // Get list of search terms
    searchMap.put( country, new ArrayList<String>( Arrays.asList(searchTerms) ) ); // Setup hashmap
  }

  // "secure/login.txt" is not included in the repository, downloaders must create this directory with their own login data
  String[] loginInfo = loadStrings( "secure/login.txt" );
  twitter = getTwitterStream( loginInfo[0], loginInfo[1], loginInfo[2], loginInfo[3] ); // Consumer Key, Consumer Secret, Access Token, Access Token Secret

  StatusListener listener = new StatusListener() {
    public void onStatus(Status status) {
      // This is executed on every new Status 
      
      String tweetBody = status.getText();
      for ( String country : searchMap.keySet() ) {
        for ( String searchTerm : searchMap.get( country ) ) {
          searchTerm = searchTerm.toLowerCase();
          if ( tweetBody.toLowerCase().contains( " " + searchTerm + " " ) || tweetBody.toLowerCase().contains( " #" + searchTerm + " " )) {
            if ( tweetMap.get( country ) == null ) {
              tweetMap.put( country, new ArrayList< String >() );
            }
            tweetMap.get( country ).add( tweetBody );
            countriesFound++;
            break;
          }
        }
      }
      println( countriesFound, ++tweetsChecked );
    }
    
    public void onDeletionNotice(StatusDeletionNotice statusDeletionNotice) {
    }
    public void onTrackLimitationNotice(int numberOfLimitedStatuses) {
    }
    public void onStallWarning( StallWarning stallWarning ) {
    }
    public void onScrubGeo( long a, long b ) {
    }
    public void onException(Exception ex) {
      ex.printStackTrace();
    }
  };

  twitter.addListener(listener);
  twitter.sample("en");
}

void draw() {
  Table countryTable = geoMap.getAttributeTable();

  int greatestTweetCount = 0;
  for ( String country : tweetMap.keySet() ) {
    if ( tweetMap.get( country ).size() > greatestTweetCount ) {
      greatestTweetCount = tweetMap.get( country ).size();
    }
  }

  for ( String country : searchMap.keySet() ) {
    int id = getID( country, countryTable );
    if ( tweetMap.get( country ) != null ) {
      if ( id == -1 ) {
        println( country + " could not be found!" );
      } else {
        fill( 255, map( sqrt( tweetMap.get( country ).size() ), 0, sqrt( greatestTweetCount ), 255, 0 ), 255 );
        geoMap.draw( id );
      }
    } else { 
      if ( id == -1 ) {
        println( country + " could not be found!" );
      } else {
        fill( 255, 255, 255 );
        geoMap.draw( id );
      }
    }
  }
}

void mouseClicked() {
  twitter.shutdown();
  twitter.cleanUp();
  List<String> results = new ArrayList();
  for ( String country : tweetMap.keySet() ) {
    results.add( country + "\t" + tweetMap.get( country ).size() );
    saveStrings( "out/countries/" + country + ".txt", tweetMap.get( country ).toArray( new String[0] ) );
  }
  saveStrings( "out/countries/results.txt", results.toArray( new String[0] ) );
  exit();
}

TwitterStream getTwitterStream( String consumerKey, String consumerSecret, String accessToken, String accessSecret ) {
  ConfigurationBuilder cb = new ConfigurationBuilder();
  cb.setDebugEnabled(true)
    .setOAuthConsumerKey(consumerKey)
    .setOAuthConsumerSecret(consumerSecret)
    .setOAuthAccessToken(accessToken)
    .setOAuthAccessTokenSecret(accessSecret);
  TwitterStreamFactory tf = new TwitterStreamFactory(cb.build());
  return tf.getInstance();
}

int getID( String string, Table table ) {
  int myID = -1;
  for ( TableRow row : table.rows() ) {
    if ( row.getString(3).contains( string ) ) {
      myID = row.getInt( 0 );
      break;
    }
  }
  return myID;
}