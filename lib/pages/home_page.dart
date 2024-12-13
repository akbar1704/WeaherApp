import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/key.dart';
import 'package:weather_app/pages/forecast_page.dart';
import 'package:weather_app/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? userDetails;

  const HomePage({Key? key, this.userDetails}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _weather;
  String? _city = "Malang";
  List<dynamic> _searchResults = [];
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? userDetails;

  @override
  void initState() {
    super.initState();
    userDetails = widget.userDetails;
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    if (_city == null || _city!.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse(
            'http://api.weatherapi.com/v1/current.json?key=$weatherApiKey&q=$_city&aqi=yes'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _weather = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _searchCity(String query) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.weatherapi.com/v1/search.json?key=$weatherApiKey&q=$query'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _searchResults = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load search results');
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    }
  }

  void _onCitySelected(String city) {
    setState(() {
      _city = city;
      _searchResults = [];
      _searchController.clear();
    });
    _fetchWeather();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error Occurred'),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: Text(
          'Weather App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue[800],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.cloud_outlined, color: Colors.blue[800]),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ForecastPage(city: _city),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.person_outline, color: Colors.blue[800]),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(
                      userDetails: userDetails!), // Navigate to ProfilePage
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.blue[800],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchWeather,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildSearchBar(),
                    if (_weather != null) _buildUI(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                labelText: 'Search City',
                prefixIcon: Icon(Icons.search, color: Colors.blue[800]),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.blue[800]!, width: 2),
                ),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _searchCity(value);
                } else {
                  setState(() {
                    _searchResults = [];
                  });
                }
              },
            ),
          ),
          if (_searchResults.isNotEmpty)
            Container(
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
              margin: EdgeInsets.only(top: 10),
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  var city = _searchResults[index];
                  return ListTile(
                    title: Text(
                      '${city['name']}, ${city['region']}, ${city['country']}',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      _onCitySelected(city['name']);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUI() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _locationHeader(),
          const SizedBox(height: 16),
          _dateTimeInfo(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _weatherIcon()),
              Expanded(child: _currentTemp()),
            ],
          ),
          const SizedBox(height: 16),
          _extraInfo(),
        ],
      ),
    );
  }

  Widget _locationHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[800]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Text(
        _weather?['location']['name'] ?? "",
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _dateTimeInfo() {
    DateTime now = DateTime.parse(_weather!['location']['localtime']);
    return Container(
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
        children: [
          Text(
            DateFormat("h:mm a").format(now),
            style: TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat("EEEE").format(now),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                "  ${DateFormat("d.M.y").format(now)}",
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weatherIcon() {
    return Container(
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
        children: [
          Image.network(
            "http:${_weather?['current']['condition']['icon']}",
            height: 100,
            width: 100,
          ),
          Text(
            _weather?['current']['condition']['text'] ?? "",
            style: TextStyle(
              color: Colors.blue[800],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _currentTemp() {
    return Container(
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
      child: Text(
        "${_weather?['current']['temp_c']?.toStringAsFixed(0)}° C",
        style: TextStyle(
          color: Colors.blue[800],
          fontSize: 58,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _extraInfo() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue[100]!.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Weather Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
              letterSpacing: 1.1,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          _detailedInfoGrid(),
        ],
      ),
    );
  }

  Widget _detailedInfoGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: [
        _weatherDetailCard(
          icon: Icons.air,
          label: 'Wind',
          value: "${_weather?['current']['wind_kph']?.toStringAsFixed(0)} kph",
        ),
        _weatherDetailCard(
          icon: Icons.wind_power,
          label: 'Gust',
          value: "${_weather?['current']['gust_kph']} kph",
        ),
        _weatherDetailCard(
          icon: Icons.water_drop_outlined,
          label: 'Humidity',
          value: "${_weather?['current']['humidity']?.toStringAsFixed(0)}%",
        ),
        _weatherDetailCard(
          icon: Icons.compress,
          label: 'Pressure',
          value: "${_weather?['current']['pressure_mb']} mb",
        ),
        _weatherDetailCard(
          icon: Icons.visibility,
          label: 'Visibility',
          value: "${_weather?['current']['vis_km']} km",
        ),
        _weatherDetailCard(
          icon: Icons.wb_sunny_outlined,
          label: 'UV Index',
          value: "${_weather?['current']['uv']}",
        ),
        _weatherDetailCard(
          icon: Icons.water,
          label: 'Precipitation',
          value: "${_weather?['current']['precip_mm']} mm",
        ),
        _weatherDetailCard(
          icon: Icons.adjust,
          label: 'Wind Dir',
          value: "${_weather?['current']['wind_dir']}",
        ),
        _weatherDetailCard(
          icon: Icons.waves,
          label: 'PM2.5',
          value:
              "${_weather?['current']['air_quality']['pm2_5']?.toStringAsFixed(1)} µg/m³",
        ),
      ],
    );
  }

  Widget _weatherDetailCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue[100]!, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.blue[800],
            size: 30,
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.blue[900],
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
