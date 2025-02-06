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