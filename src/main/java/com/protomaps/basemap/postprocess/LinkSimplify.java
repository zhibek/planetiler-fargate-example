package com.protomaps.basemap.postprocess;

import com.onthegomap.planetiler.VectorTile;
import com.onthegomap.planetiler.geo.GeometryException;
import com.onthegomap.planetiler.geo.GeometryType;
import java.util.*;
import org.locationtech.jts.geom.Coordinate;


public class LinkSimplify {

  private LinkSimplify() {}

  /**
   * Post-processing to remove "complexity" from lines.
   */
  public static List<VectorTile.Feature> linkSimplify(List<VectorTile.Feature> items, String key, String mainval,
    String linkval) throws GeometryException {

    Map<Coordinate, Integer> degrees = new HashMap<>();

    for (VectorTile.Feature item : items) {
      if (item.geometry().geomType() == GeometryType.LINE) {
        if (item.attrs().get(key).equals(linkval)) {
          Coordinate[] coordinates = item.geometry().decode().getCoordinates();
          if (coordinates.length == 0)
            continue;
          Coordinate start = coordinates[0];
          Coordinate end = coordinates[coordinates.length - 1];
          if (degrees.containsKey(start)) {
            degrees.put(start, degrees.get(start) + 1);
          } else {
            degrees.put(start, 1);
          }
          if (degrees.containsKey(end)) {
            degrees.put(end, degrees.get(end) + 1);
          } else {
            degrees.put(end, 1);
          }

        } else if (item.attrs().get(key).equals(mainval)) {
          Coordinate[] coordinates = item.geometry().decode().getCoordinates();
          for (Coordinate c : coordinates) {
            if (degrees.containsKey(c)) {
              degrees.put(c, degrees.get(c) + 1);
            } else {
              degrees.put(c, 1);
            }
          }
        }
      }
    }

    List<VectorTile.Feature> output = new ArrayList<>();

    for (VectorTile.Feature item : items) {
      if (item.geometry().geomType() == GeometryType.LINE && item.attrs().get(key).equals(linkval)) {
        Coordinate[] coordinates = item.geometry().decode().getCoordinates();
        if (coordinates.length == 0)
          continue;
        Coordinate start = coordinates[0];
        Coordinate end = coordinates[coordinates.length - 1];
        if (degrees.get(start) >= 2 && degrees.get(end) >= 2) {
          output.add(item);
        }
      } else {
        output.add(item);
      }
    }
    return output;
  }
}
