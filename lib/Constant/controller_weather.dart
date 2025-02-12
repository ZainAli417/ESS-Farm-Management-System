import 'dart:convert';
import 'package:ess_fms/Constant/weather.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class WeatherController extends GetxController {
  var weather = Weather(
    cityname: "N/A",
    icon: "",
    temp: 0.0,
    humidity: 0,
    windspeed: 0.0,
    condition: "",
    forecastMaxTemp: 0.0,
    forecastMinTemp: 0.0,
    feelsLikeTemp: 0.0,
  ).obs;

  var weeklyWeatherList = <WeeklyWeather>[].obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    isLoading(true);
    errorMessage('');
    print("Location fetching started - isLoading: ${isLoading.value}, errorMessage: '${errorMessage.value}'"); // ADDED PRINT

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("Location service disabled"); // ADDED PRINT
        errorMessage.value = 'Location services are disabled.';
        isLoading(false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print("Location permission denied"); // ADDED PRINT
          errorMessage.value = 'Location permissions are denied';
          isLoading(false);
          return;
        }
      }
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      print("Location fetched successfully: ${position.latitude}, ${position.longitude}"); // ADDED PRINT
      fetchWeatherData(position.latitude, position.longitude);
      fetchWeeklyWeather(position.latitude, position.longitude);
    } catch (e) {
      print("Error getting location: $e"); // ADDED PRINT
      errorMessage.value = 'Error getting location: ${e.toString()}'; // IMPROVED ERROR HANDLING
      isLoading(false); // ENSURE isLoading is set to false on error
    } finally {
      print("Location fetching completed (finally) - isLoading: ${isLoading.value}, errorMessage: '${errorMessage.value}'"); // ADDED PRINT
    }
  }

  Future<void> fetchWeatherData(double latitude, double longitude) async {
    print("Fetching current weather data started - isLoading: ${isLoading.value}"); // ADDED PRINT
    try {
      var uri = Uri.parse(
          "http://api.weatherapi.com/v1/forecast.json?key=afa5323058974cbb9cf151657230504&q=$latitude,$longitude&days=1&aqi=no&alerts=no");
      var res = await http.get(uri);
      if (res.statusCode == 200) {
        var decodedData = jsonDecode(res.body);
        Weather fetchedWeather = Weather.fromjson(decodedData);

        var forecastday = decodedData['forecast']['forecastday'][0]['day'];
        fetchedWeather.forecastMaxTemp = forecastday['maxtemp_c'].toDouble();
        fetchedWeather.forecastMinTemp = forecastday['mintemp_c'].toDouble();
        fetchedWeather.feelsLikeTemp = decodedData['current']['feelslike_c'].toDouble();

        weather.value = fetchedWeather;
        print("Current weather data fetched successfully - City: ${weather.value.cityname}"); // ADDED PRINT
      } else {
        print("HTTP Error fetching current weather: ${res.statusCode}"); // ADDED PRINT
        errorMessage.value = 'HTTP Error fetching weather data: ${res.statusCode}'; // IMPROVED ERROR HANDLING
      }
    } catch (e) {
      print("Error fetching current weather data: $e"); // ADDED PRINT
      errorMessage.value = 'Error fetching weather data: ${e.toString()}'; // IMPROVED ERROR HANDLING
    } finally {
      isLoading(false); // ENSURE isLoading is set to false after API call (success or fail)
      print("Fetching current weather data completed (finally) - isLoading: ${isLoading.value}, errorMessage: '${errorMessage.value}'"); // ADDED PRINT
    }
  }

  /// 🔹 Fetch 7-day weather forecast
  Future<void> fetchWeeklyWeather(double latitude, double longitude) async {
    print("Fetching weekly weather data started - isLoading: ${isLoading.value}"); // ADDED PRINT
    try {
      var uri = Uri.parse(
          "http://api.weatherapi.com/v1/forecast.json?key=afa5323058974cbb9cf151657230504&q=$latitude,$longitude&days=30&aqi=yes&alerts=no");
      var res = await http.get(uri);
      if (res.statusCode == 200) {
        var decodedData = jsonDecode(res.body);
        List<WeeklyWeather> weeklyForecast = [];

        var forecastList = decodedData['forecast']['forecastday'];
        for (var day in forecastList) {
          weeklyForecast.add(WeeklyWeather.fromJson(day));
        }

        weeklyWeatherList.assignAll(weeklyForecast);
        print("Weekly weather data fetched successfully - Count: ${weeklyWeatherList.length}"); // ADDED PRINT
      }else {
        print("HTTP Error fetching weekly weather: ${res.statusCode}"); // ADDED PRINT
        errorMessage.value = 'HTTP Error fetching weekly weather data: ${res.statusCode}'; // IMPROVED ERROR HANDLING
      }
    } catch (e) {
      print("Error fetching weekly weather data: $e"); // ADDED PRINT
      errorMessage.value = 'Error fetching weekly weather data: ${e.toString()}'; // IMPROVED ERROR HANDLING
    } finally {
      // NOTE:  We should NOT set isLoading(false) here if we want to show loading until BOTH current and weekly data are fetched.
      // However, if weekly fetch fails but current is fine, UI might still be stuck.
      // Let's assume current weather fetch is essential and make UI load after current weather.
      // If you want to wait for both, you might need to manage a separate loading state for weekly data or use Future.wait in _getCurrentLocation
      print("Fetching weekly weather data completed (finally) - isLoading: ${isLoading.value}, errorMessage: '${errorMessage.value}'"); // ADDED PRINT
    }
  }
}