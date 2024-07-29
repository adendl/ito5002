export function getAverageCoordinate(listings) {
    let lat = 0;
    let lng = 0;
    for (let i = 0; i < listings.length; i++) {
        lat += listings[i].latitude;
        lng += listings[i].longitude;
    }
    let averageLat = lat / listings.length;
    let averageLong = lng / listings.length;
    return [averageLong, averageLat];
}

export function fuzzClusteredListings(listings) {
    var seenCoordinates = {};
    var fuzzedListings = [];
    for (var i = 0; i < listings.length; i++) {
        var lat = listings[i].latitude;
        var lng = listings[i].longitude;
        var key = lat + "-" + lng;
        if (!seenCoordinates[key]) {
            seenCoordinates[key] = true;
            fuzzedListings.push(listings[i]);
        } else {
            fuzzedListings.push({
                ...listings[i],
                latitude: lat + Math.random() * 0.0001,
                longitude: lng + Math.random() * 0.0001,
            });
        }
    }
    return fuzzedListings;
}

export function getZoomLevel(listings) {
    if (!listings || listings.length === 0) {
        throw new Error("The list of listings is empty.");
    }
    let minLat = Infinity,
        maxLat = -Infinity;
    let minLon = Infinity,
        maxLon = -Infinity;
    listings.forEach((listing) => {
        if (listing.latitude < minLat) minLat = listing.latitude;
        if (listing.latitude > maxLat) maxLat = listing.latitude;
        if (listing.longitude < minLon) minLon = listing.longitude;
        if (listing.longitude > maxLon) maxLon = listing.longitude;
    });
    const latDiff = maxLat - minLat;
    const lonDiff = maxLon - minLon;
    const latZoomFactor = 180;
    const lonZoomFactor = 360;
    const latZoom = Math.log2(latZoomFactor / latDiff);
    const lonZoom = Math.log2(lonZoomFactor / lonDiff);
    return Math.floor(Math.min(latZoom, lonZoom));
}