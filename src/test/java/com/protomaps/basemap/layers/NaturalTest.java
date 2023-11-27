package com.protomaps.basemap.layers;

import static com.onthegomap.planetiler.TestUtils.newPolygon;

import com.onthegomap.planetiler.reader.SimpleFeature;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

class NaturalTest extends LayerTest {
  @Test
  void simple() {
    assertFeatures(15,
      List.of(Map.of("pmap:kind", "glacier")),
      process(SimpleFeature.create(
        newPolygon(0, 0, 0, 1, 1, 1, 0, 0),
        new HashMap<>(Map.of("natural", "glacier")),
        "osm",
        null,
        0
      )));
  }
}
