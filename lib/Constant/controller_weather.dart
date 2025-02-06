import 'dart:convert';
import 'package:ess_fms/Constant/weather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class WeatherController extends GetxController {
  var weather = Weather(
    cityname: "N/A",
    icon: "",
    temp: 0.0,
    humidity: 0,
    windspeed: 0.0,
    condition: "",
    forecastMaxTemp: 0.0, // Added for forecast max temp
    forecastMinTemp: 0.0, // Added for forecast min temp
    feelsLikeTemp: 0.0,     // Added for feels like temp
  ).obs;

  @override
  void onInit() {
    super.onInit();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      fetchWeatherData(position.latitude, position.longitude);
    } catch (e) {}
  }

  Future<void> fetchWeatherData(double latitude, double longitude) async {
    try {
      var uri = Uri.parse(
          "http://api.weatherapi.com/v1/forecast.json?key=afa5323058974cbb9cf151657230504&q=$latitude,$longitude&days=1&aqi=no&alerts=no"); // Using forecast endpoint for today's forecast
      var res = await http.get(uri);
      if (res.statusCode == 200) {
        var decodedData = jsonDecode(res.body);
        Weather fetchedWeather = Weather.fromjson(decodedData); // Pass decoded data

        // Extract forecast data for today
        var forecastday = decodedData['forecast']['forecastday'][0]['day'];
        fetchedWeather.forecastMaxTemp = forecastday['maxtemp_c'].toDouble();
        fetchedWeather.forecastMinTemp = forecastday['mintemp_c'].toDouble();
        fetchedWeather.feelsLikeTemp = decodedData['current']['feelslike_c'].toDouble(); // Feels like from current condition

        weather.value = fetchedWeather;
      }
    } catch (e) {
      print("Error fetching weather data: $e"); // Print error for debugging
      weather.value = Weather( // Set default weather in case of error
        cityname: "Error",
        icon: "",
        temp: 0.0,
        humidity: 0,
        windspeed: 0.0,
        condition: "Could not load weather data",
        forecastMaxTemp: 0.0,
        forecastMinTemp: 0.0,
        feelsLikeTemp: 0.0,
      );
    }
  }
}