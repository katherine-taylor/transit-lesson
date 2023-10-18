# Notes

## Getting data for r5r

1.  Using geofrabik, download a map of the state you are interested in, in .pbf format

2.  Use protonmaps to get a rectangle of the smaller area you are interested in, you need the coordinates of the rectangle

3.  Use osmfilter osmconvert to crop your pbf file smaller (this will reduce file size/how long things need to run) (uses southwest and northeast corners of a rectangle

    ```         
    osmconvert input-data.osm.pbf -b=10.5,49,11.5,50 -o=my-output-file.pbf
    ```

4.  Get a list of points of interest from anywhere, you just need an id, latitude, and longitude

5.  Load in a GTFS feed (or many) for local transport
