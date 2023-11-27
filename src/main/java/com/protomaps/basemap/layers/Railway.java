package com.protomaps.basemap.layers;

import com.onthegomap.planetiler.FeatureCollector;
import com.onthegomap.planetiler.FeatureMerge;
import com.onthegomap.planetiler.ForwardingProfile;
import com.onthegomap.planetiler.VectorTile;
import com.onthegomap.planetiler.geo.GeometryException;
import com.onthegomap.planetiler.reader.SourceFeature;
import com.onthegomap.planetiler.util.Parse;
import com.protomaps.basemap.feature.FeatureId;
import com.protomaps.basemap.names.OsmNames;
import java.util.List;

public class Railway implements ForwardingProfile.FeatureProcessor, ForwardingProfile.FeaturePostProcessor {

  @Override
  public String name() {
    return "railway";
  }

  @Override
  public void processFeature(SourceFeature sf, FeatureCollector features) {
    if (sf.canBeLine() && sf.hasTag("railway")) {

      String kind = "rail";
      String kindDetail = sf.getString("railway");

      int minZoom = 3;

      if (sf.hasTag("railway", "funicular", "light_rail", "miniature", "monorail", "narrow_gauge", "preserved", "subway", "tram")) {
        minZoom = 9;
      }

      if (sf.hasTag("railway", "abandoned", "razed", "demolished", "removed", "construction", "platform", "proposed")) {
        minZoom = 12;
      }

      if (sf.hasTag("service", "yard", "siding", "crossover")) {
        minZoom = 12;
      }

      var feature = features.line(this.name())
        .setId(FeatureId.create(sf))
        // Core Tilezen schema properties
        .setAttr("pmap:kind", kind)
        // Used for client-side label collisions
        .setAttr("pmap:min_zoom", minZoom + 1)
        // Core OSM tags for different kinds of places
        .setAttr("layer", Parse.parseIntOrNull(sf.getString("layer")))
        .setAttr("network", sf.getString("network"))
        .setAttr("ref", sf.getString("ref"))
        .setAttr("route", sf.getString("route"))
        .setAttr("service", sf.getString("service"))

        .setAttr("highspeed", sf.getString("highspeed"))
        .setAttr("railway", sf.getString("railway"))

        .setMinPixelSize(0)        
        .setZoomRange(minZoom, 15);

      // Core Tilezen schema properties
      if (!kindDetail.isEmpty()) {
        feature.setAttr("pmap:kind_detail", kindDetail);
      }

      // Set "brunnel" (bridge / tunnel) property where "level" = 1 is a bridge, 0 is ground level, and -1 is a tunnel
      // Because of MapLibre performance and draw order limitations, generally the boolean is sufficent
      // See also: "layer" for more complicated ±6 layering for more sophisticated graphics libraries
      if (sf.hasTag("bridge") && !sf.hasTag("bridge", "no")) {
        feature.setAttr("pmap:level", 1);
      } else if (sf.hasTag("tunnel") && !sf.hasTag("tunnel", "no")) {
        feature.setAttr("pmap:level", -1);
      } else {
        feature.setAttr("pmap:level", 0);
      }

      // Server sort features so client label collisions are pre-sorted
      feature.setSortKey(minZoom);

      // TODO: (nvkelso 20230623) This should be variable, but 12 is better than 0 for line merging
      OsmNames.setOsmNames(feature, sf, 12);
    }
  }

  @Override
  public List<VectorTile.Feature> postProcess(int zoom, List<VectorTile.Feature> items) throws GeometryException {
    for (var item : items) {
      if (!item.attrs().containsKey("pmap:level")) {
        item.attrs().put("pmap:level", 0);
      }
    }

    items = FeatureMerge.mergeLineStrings(items,
      0.5, // after merging, remove lines that are still less than 0.5px long
      0.1, // simplify output linestrings using a 0.1px tolerance
      4 // remove any detail more than 4px outside the tile boundary
    );

    return items;
  }
}
