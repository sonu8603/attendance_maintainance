import 'package:geolocator/geolocator.dart';

class LocationService {
  // 🎯 फोन से करंट लोकेशन (Lat/Lng) प्राप्त करने का फंक्शन
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. चेक करो कि फोन का लोकेशन सर्विस (GPS) ऑन है या नहीं
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Please enable Location Services (GPS) in your phone.';
    }

    // 2. लोकेशन परमिशन चेक करो
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // अगर परमिशन नहीं है, तो यूजर से परमिशन मांगो
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permissions are denied.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // अगर यूजर ने हमेशा के लिए परमिशन ब्लॉक कर दी है
      throw 'Location permissions are permanently denied. Please enable them from settings.';
    }

    // 3. सब कुछ सही होने पर सटीक करंट लोकेशन रिटर्न करो
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high, // हाई एक्यूरेसी ताकि सटीक अटेंडेंस हो सके
    );
  }
}