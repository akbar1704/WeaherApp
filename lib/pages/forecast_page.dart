import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:weather_app/key.dart';

class ForecastPage extends StatefulWidget {
  final String? city;

  const ForecastPage({
    super.key,
    required this.city,
  });

  @override
  State<ForecastPage> createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> {
  Map<String, dynamic>? _forecast;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchForecast();
  }

  Future<void> _fetchForecast() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://api.weatherapi.com/v1/forecast.json?'
          'key=$weatherApiKey&q=${widget.city}&days=3&aqi=yes&alerts=yes',
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _forecast = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load forecast data');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to fetch weather data for ${widget.city}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: _buildAppBarTitle(),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildAppBarTitle() {
    final location = _forecast?['location'];
    String formattedDate = '';
    if (location != null) {
      DateTime localtime = DateTime.parse(location['localtime']);
      formattedDate = DateFormat('EEEE, MMM d, yyyy').format(localtime);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          location != null
              ? '${location['name']}, ${location['region']}'
              : 'Weather Forecast',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
            fontSize: 20,
          ),
        ),
        if (location != null)
          Text(
            'Local Time: $formattedDate',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingIndicator();
    }

    if (_errorMessage != null) {
      return _buildErrorMessage();
    }

    return _buildForecastContent();
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.blue[800],
            strokeWidth: 4,
          ),
          const SizedBox(height: 16),
          Text(
            'Fetching weather data...',
            style: TextStyle(color: Colors.blue[800]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[800],
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: Colors.blue[800],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildForecastContent() {
    return RefreshIndicator(
      onRefresh: _fetchForecast,
      color: Colors.blue[800],
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildCurrentWeatherSection(),
          _buildForecastList(),
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherSection() {
    final current = _forecast?['current'];
    if (current == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[800]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network("http:${current['condition']['icon']}"),
              const SizedBox(width: 16),
              Text(
                '${current['temp_c']}°C',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            current['condition']['text'],
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCurrentWeatherInfo(
                'Wind',
                '${current['wind_kph']} kph ${current['wind_dir']}',
              ),
              _buildCurrentWeatherInfo(
                'Humidity',
                '${current['humidity']}%',
              ),
              _buildCurrentWeatherInfo(
                'Pressure',
                '${current['pressure_mb']} mb',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeatherInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildForecastList() {
    final forecastDays = _forecast?['forecast']['forecastday'];
    if (forecastDays == null || forecastDays.isEmpty) {
      return const Center(child: Text('No forecast data available'));
    }

    return Column(
      children:
          forecastDays.map<Widget>((day) => _buildDayForecast(day)).toList(),
    );
  }

  Widget _buildDayForecast(Map<String, dynamic> day) {
    return ExpansionTile(
      title: _buildDateHeader(day['date']),
      subtitle: Text(
        'Max: ${day['day']['maxtemp_c']}°C, Min: ${day['day']['mintemp_c']}°C',
        style: TextStyle(color: Colors.grey[700]),
      ),
      children: day['hour']
          .map<Widget>((hour) => _buildHourlyForecast(hour))
          .toList(),
    );
  }

  Widget _buildDateHeader(String date) {
    return Text(
      DateFormat('EEEE, MMM d, yyyy').format(DateTime.parse(date)),
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue[800],
      ),
    );
  }

  Widget _buildHourlyForecast(Map<String, dynamic> hour) {
    String hourTime = _extractHourFromTimestamp(hour['time']);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHourTitle(hourTime),
            const SizedBox(height: 8),
            _buildTemperatureRow(hour),
            const SizedBox(height: 8),
            _buildWeatherDetailsRow(hour),
          ],
        ),
      ),
    );
  }

  String _extractHourFromTimestamp(String fullTimestamp) {
    return fullTimestamp.split(' ')[1];
  }

  Widget _buildHourTitle(String time) {
    return Text(
      time,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue[800],
      ),
    );
  }

  Widget _buildTemperatureRow(Map<String, dynamic> hour) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTemperatureDetails(hour),
        Image.network("http:${hour['condition']['icon']}"),
      ],
    );
  }

  Widget _buildTemperatureDetails(Map<String, dynamic> hour) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Temp: ${hour['temp_c']}°C",
          style: TextStyle(
            color: Colors.blue[800],
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          "Condition: ${hour['condition']['text']}",
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherDetailsRow(Map<String, dynamic> hour) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _infoColumn("Wind", "${hour['wind_kph']} kph"),
        _infoColumn("Humidity", "${hour['humidity']}%"),
        _infoColumn("Pressure", "${hour['pressure_mb']} mb"),
        _infoColumn("Visibility", "${hour['vis_km']} km"),
      ],
    );
  }

  Widget _infoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
      ],
    );
  }
}
