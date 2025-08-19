// Central place for your backend base URL + endpoint paths.
// NOTE on base URLs:
// - Android Emulator → use "http://10.0.2.2:8000" to access host machine.
// - iOS Simulator (on same Mac) → "http://127.0.0.1:8000".
// - Physical device → replace with your computer's LAN IP, e.g. "http://192.168.1.50:8000".


class ApiConfig {
// Change this to match your environment
static const String baseUrl = "http://127.0.0.1:8000"; // Android emulator default
static const String chatPath = "/chat";


static Uri chatUri() => Uri.parse(baseUrl + chatPath);
}


