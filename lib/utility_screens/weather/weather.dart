import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';
import 'package:location/location.dart';
import 'weather_dialog.dart';

enum AppState { NOT_DOWNLOADED, DOWNLOADING, FINISHED_DOWNLOADING }

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  late String apiKey;
  late WeatherFactory ws;
  List<Weather> _data = [];
  var location;
  var temp;
  var weatherType;
  var weathercode;
  final DateFormat date = DateFormat('dd LLL');
  final DateFormat time = DateFormat('HH:mm');
  AppState _state = AppState.NOT_DOWNLOADED;
  double? lat, lon;

  @override
  void initState() {
    super.initState();
    apiKey = dotenv.env["OPENWEATHERMAP_API_KEY"] ?? 'nothing';
    ws = WeatherFactory(apiKey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text("Weather"),
      ),
      body: apiKey == "nothing"
          ? const Center(child: Text("API key not provided"))
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _coordinateInputs(),
                  _buttons(),
                  const Divider(
                    height: 20.0,
                    thickness: 2.0,
                  ),
                  Flexible(child: _resultView())
                ],
              ),
            ),
    );
  }

  void queryForecast() async {
    /// Removes keyboard
    FocusScope.of(context).requestFocus(FocusNode());
    setState(() {
      _state = AppState.DOWNLOADING;
    });

    List<Weather> forecasts = await ws.fiveDayForecastByLocation(lat!, lon!);
    setState(() {
      _data = forecasts;
      _state = AppState.FINISHED_DOWNLOADING;
    });
  }

  void queryWeather() async {
    /// Removes keyboard
    FocusScope.of(context).requestFocus(FocusNode());

    setState(() {
      _state = AppState.DOWNLOADING;
    });

    Weather weather = await ws.currentWeatherByLocation(lat!, lon!);

    setState(() {
      location = weather.areaName;
      temp = weather.temperature!.celsius!.round();
      weatherType = weather.weatherDescription;
      weathercode = weather.weatherConditionCode!;
      _data = [weather];
      _state = AppState.FINISHED_DOWNLOADING;
      print(location);
      print(temp);
      print(weatherType);
    });
  }

  Widget weatherUI() {
    return Container(
        margin: EdgeInsets.all(15),
        child: GestureDetector(
          onTap: () {
            WeatherDialog().showDetails(_data[0], context);
          },
          child: Card(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(100, 30, 100, 15),
                  child: FittedBox(
                    child: WeatherDialog().getWeatherImage(weathercode),
                    fit: BoxFit.contain,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Temperature: ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      temp.toString(),
                      style: TextStyle(fontSize: 15),
                    ),
                    Text(
                      '°C',
                      style: TextStyle(fontSize: 15),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Description: ',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      weatherType,
                      style: TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  Widget forecastUI() {
    return Container(
      margin: EdgeInsets.all(10),
      height: 250,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _data.length,
        itemBuilder: (context, index) {
          // return ListTile(
          //   title: Text(_data[index].toString()),
          // );
          return GestureDetector(
            onTap: () => WeatherDialog().showDetails(_data[index], context),
            child: Card(
                child: Container(
              margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
              width: 160.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Text(
                    date.format(_data[index].date!),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  Text(
                    time.format(_data[index].date!),
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                  Container(
                    height: 15,
                  ),
                  SizedBox(
                    height: 70,
                    width: 70,
                    child: WeatherDialog()
                        .getWeatherImage(_data[index].weatherConditionCode!),
                  ),
                  Container(
                    height: 15,
                  ),
                  Text(
                    _data[index]
                            .temperature!
                            .celsius!
                            .roundToDouble()
                            .toString() +
                        '°C',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            )),
          );
        },
      ),
    );
  }

  Widget contentFinishedDownload() {
    return Center(
      child: Column(
        children: [
          Text(
            location,
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
          ),
          _data.length < 2 ? weatherUI() : forecastUI(),
        ],
      ),
    );
  }

  Widget contentDownloading() {
    return Container(
      margin: const EdgeInsets.all(25),
      child: Column(children: [
        const Text(
          'Fetching Weather...',
          style: TextStyle(fontSize: 20),
        ),
        Container(
            margin: const EdgeInsets.only(top: 50),
            child:
                const Center(child: CircularProgressIndicator(strokeWidth: 10)))
      ]),
    );
  }

  Widget contentNotDownloaded() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Text(
            'Press the button to download the Weather forecast',
          ),
        ],
      ),
    );
  }

  Widget _resultView() => _state == AppState.FINISHED_DOWNLOADING
      ? contentFinishedDownload()
      : _state == AppState.DOWNLOADING
          ? contentDownloading()
          : contentNotDownloaded();

  void _saveLat(String input) {
    lat = double.tryParse(input);
    print(lat);
  }

  void _saveLon(String input) {
    lon = double.tryParse(input);
    print(lon);
  }

  Widget _coordinateInputs() {
    var _latitude = new TextEditingController(text: '');
    var _longitude = new TextEditingController(text: '');

    return Container(
      margin: EdgeInsets.fromLTRB(10, 15, 10, 5),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: Colors.black54),
        boxShadow: const [
          BoxShadow(
              color: Colors.black45, blurRadius: 10, offset: Offset(1, 1)),
        ],
      ),
      padding: EdgeInsets.all(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: <Widget>[
              Text('Latitude:    '),
              Expanded(
                child: Container(
                    margin: const EdgeInsets.all(5),
                    child: TextField(
                        controller: _latitude,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter latitude'),
                        keyboardType: TextInputType.number,
                        onChanged: _saveLat,
                        onSubmitted: _saveLat)),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Text('Longitude: '),
              Expanded(
                  child: Container(
                      margin: const EdgeInsets.all(5),
                      child: TextField(
                          controller: _longitude,
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter longitude'),
                          keyboardType: TextInputType.number,
                          onChanged: _saveLon,
                          onSubmitted: _saveLon))),
            ],
          ),
          Container(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Divider(
                height: 8,
              ),
              Text(
                'OR',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const Divider(
                height: 8,
              ),
            ],
          ),
          Container(
            height: 20,
          ),
          ElevatedButton(
              onPressed: () async {
                Location location = Location();
                bool _serviceEnabled = await location.serviceEnabled();
                if (!_serviceEnabled) {
                  _serviceEnabled = await location.requestService();
                }
                if (_serviceEnabled) {
                  PermissionStatus _permissionGranted =
                      await location.hasPermission();
                  //print(_permissionGranted);
                  if (_permissionGranted == PermissionStatus.denied) {
                    _permissionGranted = await location.requestPermission();
                  }
                  //print(_permissionGranted);
                  if (_permissionGranted == PermissionStatus.granted) {
                    LocationData _locationData = await location.getLocation();
                    lat = _locationData.latitude;
                    lon = _locationData.longitude;
                    print(lat);
                    print(lon);
                    _latitude.text = lat.toString();
                    _longitude.text = lon.toString();
                  }
                }
              },
              child: const Text("Get current location"))
        ],
      ),
    );
  }

  Widget _buttons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.all(5),
          child: TextButton(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_outlined),
                  const Text(
                    'Fetch weather',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              onPressed: queryWeather),
        ),
        Container(
          margin: const EdgeInsets.all(5),
          child: TextButton(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_sharp),
                  const Text(
                    'Fetch forecast',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              onPressed: queryForecast),
        ),
      ],
    );
  }
}
