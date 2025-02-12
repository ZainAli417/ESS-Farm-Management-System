class Weather {
  String cityname;
  String condition;
  double temp;
  double windspeed;
  int humidity;
  String icon;
  double forecastMaxTemp; // Added for forecast max temp
  double forecastMinTemp; // Added for forecast min temp
  double feelsLikeTemp;     // Added for feels like temp


  Weather({
    required this.cityname,
    required this.condition,
    required this.temp,
    required this.windspeed,
    required this.humidity,
    required this.icon,
    this.forecastMaxTemp = 0.0, // Initialize with default value
    this.forecastMinTemp = 0.0, // Initialize with default value
    this.feelsLikeTemp = 0.0,     // Initialize with default value
  });

  factory Weather.fromjson(Map<String, dynamic> json) {
    return Weather(
      cityname: json['location']['name'],
      condition: json['current']['condition']['text'],
      temp: json['current']['temp_c'],
      windspeed: json['current']['wind_kph'],
      humidity: json['current']['humidity'],
      icon: json['current']['condition']['icon'],
      forecastMaxTemp: 0.0, // Will be updated after parsing forecast data
      forecastMinTemp: 0.0, // Will be updated after parsing forecast data
      feelsLikeTemp: 0.0,    // Will be updated after parsing forecast data
    );
  }
}
class WeeklyWeather {
  final String date;
  final double maxTemp;
  final double minTemp;

  final String condition;
  final String icon;

  WeeklyWeather({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.condition,
    required this.icon,
  });

  factory WeeklyWeather.fromJson(Map<String, dynamic> json) {
    return WeeklyWeather(
      date: json['date'],
      maxTemp: json['day']['maxtemp_c'].toDouble(),
      minTemp: json['day']['mintemp_c'].toDouble(),
      condition: json['day']['condition']['text'],
      icon: json['day']['condition']['icon'],
    );
  }
}
