+++
date = "2023-06-19T21:30:55Z"
title = "Creating Self-Hosted Tile Maps from OpenStreetMap Data"
description = "Rendering the self-hosted tiles for a slippy map using OpenStreetMap data."
+++

{{< figure src="/media/46/37cf2cce580db1a9863996e0037ab83ef0bce4ab3b1f6bf51acd3ef7a0e37d.png" caption="The work-in-progess homepage of NLAlerts, showing the most recent alerts." >}}

I've been working on [NLAlerts](https://nlalerts.terin.nl), a project to archive and display the mobile emergency alerts sent by the Netherlands government. The data provided by the government includes the text of the alert, along with targetted geographical area. With JavaScript libraries such as [Leaflet](https://leafletjs.com/) or [OpenLayers](https://openlayers.org/) it is easy to turn this geographical area onto an interactive map.

These libraries can be used with external tile servers, such as the one provided by OpenStreetMap or one of the many commercial offerings. However, I wanted self-host all the data required for the website, which includes the map tiles. Rendered tiles can be stored in a SQLite database following the [MBTiles Specification](https://github.com/mapbox/mbtiles-spec). Since the NLAlerts site already uses SQLite by way of being powered by data exploration framework [Datasette](https://datasette.io), using MBTiles would be fairly complimentary. In fact, there's already a plugin [datasette-tiles](https://datasette.io/plugins/datasette-tiles) to have Datasette act as a tileserver.

This just left one remaining problems: _How do I get OpenStreetMap data into MBTiles?_ I found many guides online, but they seemed to fall into one of two camps: they were written many years ago and they suffer from linkrot or bitrot, or they ripped tiles from other servers. The former problem makes it hard to follow these guides in 2023, the latter is often against the terms of service (or rude to the remaining operators of non-profit tileservers).

This past weekend I was able to cobble together a working pipeline to "pre-render" tiles from OpenStreetMap extracts to MBTiles.

I first started by downloading the "osm.pbf" file for the Netherlands from [Geofabrik](https://download.geofabrik.de/europe/netherlands.html). This file is the OpenStreetMap data in Protobuf format.

I then used the [openstreetmap-tile-server](https://github.com/Overv/openstreetmap-tile-server) container to import the "osm.pbf" file into PostGIS. I created volumes to store the database (`osm-data`) as well as where the tiles would later be rendered to (`osm-tiles`).

```
podman volume create osm-data
podman volume create osm-tiles

podman run -v $PWD/netherlands-latest.osm.pbf \
           -v osm-data:/data/database \
           -v osm-tiles:/data/tiles \
           overv/openstreetmap-tile-server:2.3.0 \
           import
```

After several minutes, the container should exit successfully and all the data will be imported. The same image could be used to run the renderer. I had to increase the shared memory configured in the container to avoid rendering errors later.

```
podman run -v osm-data:/data/database \
           -v osm-tiles:/data/tiles \
           -shm-size=1G \
           overv/openstreetmap-tile-server:2.3.0 \
           run
```

In another terminal we could exec into this container to start the pre-rendering.

```
podman exec -it --latest bash
```

Within the container, we can fetch the `render_list_geo.pl` script, which wraps the `render_list` command to render within a bounding box at different zoom levels. I then ran the script with the bounding box determined with the  [https://boundingbox.klokantech.com/](Bounding Box Tool) for zoom levels 8 through 13.

```
wget https://raw.githubusercontent.com/alx77/render_list_geo.pl/master/render_list_geo.pl
perl ./render_list_geo.pl -z 8 -Z 13 \
    -x 3.3316001 -X 7.2275102 \
    -y 50.7503838 -Y 53.6316
```

If all went well, we can exit and stop the container, now having completed the hardest part. We have the map rendered in the `osm-tiles`, unfortunately not in a format we can directly use, but instead in [meta tile](https://wiki.openstreetmap.org/wiki/Meta_tiles), which can be efficiently used by `mod_tile`.

Fortunately, Geofabrik has a tool to help us out, [meta2tile](https://github.com/geofabrik/meta2tile), which can be used to generate MBTiles databases. After cloning the repository, I built the tool in the most barebones configuration, only enabling MBTiles support.

```
gcc -DWITH_MBTILES meta2tile.c -o meta2tile -lsqlite3 -lcrypto -lm -O3
```

It's worth noting that `meta2tile` uses the deprecated `MD5` function from OpenSSL, which may stop being provided in a future version of OpenSSL. Fortunately, it's also not the most difficult function to replace.

On my system Podman runs in rootless mode, with volumes being plain directories on disks. Thus I was able to run `meta2tile` directly against this directory. You may need to mount the volume or copy the data out first.

```
meta2tile --mbtiles \
          --meta name="Netherlands" \
          --meta type=raster \
          --meta format=png \
          --meta version=1.0 \
          --meta bounds="3.3316001,50.7503838,7.2275102,53.6316" \
          --meta description="OpenStreetMap tiles for Netherlands"
          /home/terin/.local/share/containers/storage/volumes/osm-tiles/_data/default/ \
          nl.db
```

I was then able to start Datasette with the datasette-tiles plugin installed and browse to `http://localhost:8001/-/tiles/nl/` and browse my tiles.

{{< figure src="/media/91/b5d02f42066b1b588292231c3386688099374679ad8d6a3fe81731ff322f6a.png" caption="The alert page showing a test alert sent, rendering the targetted area with OpenLayers." >}}

When creating my template for the custom alert pages, I was able to reference `"/-/tiles/nl/{z}/{x}/{y}.png"` as the location of the tileserver. The result can be seen on this [test alert](https://nlalerts.terin.nl/alerts/c2006b50-7179-498d-bddd-933899f354bd).
