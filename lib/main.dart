import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart'; // Uncomment if using Provider

// --- Constants for Preferences ---
const String prefKeyTheme = 'app_theme'; // 'system', 'light', 'dark'
const String prefKeySound = 'scan_sound_enabled'; // bool
const String prefKeyVibrate = 'scan_vibrate_enabled'; // bool
const String prefKeyBrowser = 'default_browser'; // 'in_app', 'external'
const String prefKeyHistory = 'history_management'; // 'keep', 'delete_30d'

// --- Permission Handling Logic ---

// Helper function to request a single permission
Future<bool> requestPermission(
    Permission permission, BuildContext context) async {
  final status = await permission.status;

  if (status.isGranted) {
    debugPrint('${permission.toString()} permission already granted.');
    return true;
  }

  if (status.isDenied) {
    final result = await permission.request();
    if (result.isGranted) {
      debugPrint('${permission.toString()} permission granted.');
      return true;
    } else {
      debugPrint('${permission.toString()} permission denied by user.');
      if (context.mounted) {
        // Check if context is still valid
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${_permissionNameToFriendlyName(permission)} permission was denied.')),
        );
      }
      return false;
    }
  }

  if (status.isPermanentlyDenied) {
    debugPrint('${permission.toString()} permission permanently denied.');
    if (context.mounted) {
      // Check if context is still valid
      _showSettingsDialog(permission, context);
    }
    return false;
  }

  if (status.isRestricted) {
    debugPrint('${permission.toString()} permission is restricted.');
    if (context.mounted) {
      // Check if context is still valid
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${_permissionNameToFriendlyName(permission)} permission is restricted by device policy.')),
      );
    }
    return false;
  }

  // Handle other potential statuses (limited access for photos, etc.) if necessary
  debugPrint('${permission.toString()} unknown status: $status');
  return false;
}

// Helper to show dialog directing user to app settings
void _showSettingsDialog(Permission permission, BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(
          '${_permissionNameToFriendlyName(permission)} Permission Required'),
      content: Text(
          'You have permanently denied the ${_permissionNameToFriendlyName(permission).toLowerCase()} permission. Please go to app settings to enable it.'),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('Open Settings'),
          onPressed: () {
            openAppSettings(); // Provided by permission_handler
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  );
}

// Helper to make permission names more user-friendly
String _permissionNameToFriendlyName(Permission permission) {
  if (permission == Permission.camera) return 'Camera';
  if (permission == Permission.photos || permission == Permission.photosAddOnly)
    return 'Photo Library';
  if (permission == Permission.contacts) return 'Contacts';
  if (permission == Permission.calendar ||
      permission == Permission.calendarWriteOnly ||
      permission == Permission.calendarFullAccess) return 'Calendar';
  if (permission == Permission.location ||
      permission == Permission.locationWhenInUse ||
      permission == Permission.locationAlways) return 'Location';
  return 'Required'; // Default
}

// --- Main App Entry Point ---
void main() {
  // Ensure widgets are initialized before loading preferences/providers
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Initialize SharedPreferences or Provider here if needed synchronously
  runApp(
    // TODO: Wrap with ChangeNotifierProvider if using Provider for theme/settings
    const QRScannerApp(),
  );
}

// --- Main App Widget ---
class QRScannerApp extends StatefulWidget {
  const QRScannerApp({super.key});

  @override
  State<QRScannerApp> createState() => _QRScannerAppState();
}

class _QRScannerAppState extends State<QRScannerApp> {
  ThemeMode _themeMode = ThemeMode.dark; // Default theme

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    // TODO: Add listener here if using Provider for theme updates
  }

  Future<void> _loadThemePreference() async {
    // TODO: Replace with Provider state if using Provider
    try {
      final prefs = await SharedPreferences.getInstance();
      String themePref = prefs.getString(prefKeyTheme) ?? 'system';
      setState(() {
        _themeMode = themePref == 'light'
            ? ThemeMode.light
            : (themePref == 'dark' ? ThemeMode.dark : ThemeMode.system);
      });
    } catch (e) {
      debugPrint("Error loading theme preference: $e");
      // Keep default theme
    }
  }

  // TODO: If NOT using Provider, you need a way for SettingsScreen to update the theme here.
  // One way is to pass a callback function down, but Provider is cleaner.
  void updateTheme(ThemeMode newThemeMode) {
    setState(() {
      _themeMode = newThemeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Listen to theme changes if using Provider
    // final themeProvider = Provider.of<ThemeProvider>(context); // Example

    return MaterialApp(
      title: 'QR Scanner App',
      themeMode: _themeMode, // Use dynamic theme mode
      theme: ThemeData(
        // Light Theme definition
        brightness: Brightness.light,
        primarySwatch: Colors.cyan,
        colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.cyan, brightness: Brightness.light),
        scaffoldBackgroundColor: Colors.grey[100],
        cardColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.cyan,
          elevation: 1,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.cyan,
          unselectedItemColor: Colors.grey[600],
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          elevation: 4,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
          titleMedium:
              TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
          labelSmall: TextStyle(color: Colors.black54, fontSize: 11),
        ),
        iconTheme: IconThemeData(color: Colors.grey[700]),
        dividerColor: Colors.grey[300],
        tabBarTheme: TabBarTheme(
          indicatorColor: Colors.cyan,
          labelColor: Colors.cyan,
          unselectedLabelColor: Colors.grey[600],
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Colors.cyan,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith<Color?>((states) =>
              states.contains(MaterialState.selected) ? Colors.cyan : null),
          trackColor: MaterialStateProperty.resolveWith<Color?>((states) =>
              states.contains(MaterialState.selected)
                  ? Colors.cyan.withOpacity(0.5)
                  : null),
        ),
        snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.grey[800],
            contentTextStyle: const TextStyle(color: Colors.white)),
        dialogTheme: DialogTheme(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
        bottomSheetTheme: const BottomSheetThemeData(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)))),
      ),
      darkTheme: ThemeData(
        // Dark Theme definition
        brightness: Brightness.dark,
        primarySwatch: Colors.cyan,
        colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.cyan,
            brightness: Brightness.dark,
            accentColor: Colors.cyanAccent),
        scaffoldBackgroundColor: const Color(0xFF1F1F1F),
        cardColor: const Color(0xFF2C2C2E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1F1F1F),
          selectedItemColor: Color(0xFF00BCD4),
          unselectedItemColor: Colors.grey,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          elevation: 4,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white70),
          titleMedium:
              TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          labelSmall: TextStyle(color: Colors.white70, fontSize: 11),
        ),
        iconTheme: const IconThemeData(color: Colors.white70),
        dividerColor: Colors.grey[800],
        tabBarTheme: TabBarTheme(
          indicatorColor: const Color(0xFF00BCD4),
          labelColor: const Color(0xFF00BCD4),
          unselectedLabelColor: Colors.grey[400],
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xFF00BCD4),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith<Color?>((states) =>
              states.contains(MaterialState.selected)
                  ? const Color(0xFF00BCD4)
                  : null),
          trackColor: MaterialStateProperty.resolveWith<Color?>((states) =>
              states.contains(MaterialState.selected)
                  ? const Color(0xFF00BCD4).withOpacity(0.5)
                  : null),
        ),
        snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF333333),
            contentTextStyle: TextStyle(color: Colors.white)),
        dialogTheme: DialogTheme(
            backgroundColor: const Color(0xFF2C2C2E),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
        bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Color(0xFF2C2C2E),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)))),
      ),
      debugShowCheckedModeBanner: false,
      home:
          const MainScreen(), // Pass the updateTheme callback if not using Provider
      routes: {
        '/settings': (context) =>
            SettingsScreen(onThemeChanged: updateTheme), // Pass callback
      },
    );
  }
}

// --- Main Screen (Bottom Navigation) ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // Start with Scan screen

  // Keep instances of screens to preserve state with IndexedStack
  final List<Widget> _widgetOptions = <Widget>[
    const CreateScreen(),
    const ScanScreen(),
    const HistoryScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        // Use IndexedStack to preserve state
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined),
              activeIcon: Icon(Icons.add_box),
              label: 'Create'),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_outlined),
              activeIcon: Icon(Icons.qr_code_scanner),
              label: 'Scan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

// --- Create Screen ---
class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.settings_outlined), // Changed icon
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings')),
        title: const Text('Create Code'),
        actions: [
          IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'About',
              onPressed: () {/* TODO: Show About Dialog */}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... (QR Codes Grid as before) ...
            Text('QR Codes',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontSize: 16)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
              children: const [
                _GridButton(
                    icon: Icons.content_paste,
                    label: 'Clipboard',
                    color: Colors.green),
                _GridButton(
                    icon: Icons.link, label: 'Website', color: Colors.blue),
                _GridButton(
                    icon: Icons.wifi,
                    label: 'Wi-Fi',
                    color: Colors.lightBlueAccent),
                _GridButton(
                    icon: Icons.text_fields,
                    label: 'Text',
                    color: Colors.orange),
                _GridButton(
                    icon: Icons.person_outline,
                    label: 'Contact (vCard)',
                    color: Colors.purpleAccent),
                _GridButton(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    color: Colors.pinkAccent),
                _GridButton(
                    icon: Icons.phone_outlined,
                    label: 'Phone Number',
                    color: Colors.deepPurpleAccent),
                _GridButton(
                    icon: Icons.sms_outlined,
                    label: 'SMS',
                    color: Colors.amber),
                _GridButton(
                    icon: Icons.event,
                    label: 'Calendar Event',
                    color: Colors.teal),
                _GridButton(
                    icon: Icons.location_on_outlined,
                    label: 'Geo Location',
                    color: Colors.red),
                _GridButton(
                    icon: Icons.store_mall_directory_outlined,
                    label: 'App Store Link',
                    color: Colors.indigo),
              ],
            ),
            const SizedBox(height: 24),
            // ... (Barcodes Grid as before) ...
            Text('Barcodes',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontSize: 16)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
              children: const [
                _GridButton(
                    icon: Icons.barcode_reader,
                    label: 'EAN-8',
                    color: Colors.redAccent),
                _GridButton(
                    icon: Icons.barcode_reader,
                    label: 'EAN-13',
                    color: Colors.redAccent),
                _GridButton(
                    icon: Icons.barcode_reader,
                    label: 'UPC-E',
                    color: Colors.redAccent),
                _GridButton(
                    icon: Icons.barcode_reader,
                    label: 'UPC-A',
                    color: Colors.redAccent),
                _GridButton(
                    icon: Icons.barcode_reader,
                    label: 'CODE-39',
                    color: Colors.redAccent),
                _GridButton(
                    icon: Icons.barcode_reader,
                    label: 'CODE-93',
                    color: Colors.redAccent),
                _GridButton(
                    icon: Icons.barcode_reader,
                    label: 'CODE-128',
                    color: Colors.redAccent),
                _GridButton(
                    icon: Icons.grid_on,
                    label: 'Data Matrix',
                    color: Colors.deepOrange),
                _GridButton(
                    icon: Icons.view_column,
                    label: 'PDF417',
                    color: Colors.deepOrange),
                _GridButton(
                    icon: Icons.apps, label: 'Aztec', color: Colors.deepOrange),
              ],
            ),
            const SizedBox(height: 20),
            // Placeholder for Customization info
            Card(
              elevation: 0,
              color: Theme.of(context).cardColor.withOpacity(0.5),
              child: const ListTile(
                dense: true,
                leading: Icon(Icons.color_lens_outlined, size: 18),
                title: Text("QR Customization", style: TextStyle(fontSize: 13)),
                subtitle: Text(
                    "Color, logo & error level options available after entering data.",
                    style: TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper Grid Button
class _GridButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _GridButton({
    required this.icon,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          /* TODO: Handle button tap - navigate to specific creation form */ ScaffoldMessenger
                  .of(context)
              .showSnackBar(SnackBar(
            content: Text('Create $label (Not Implemented)'),
            duration: const Duration(seconds: 1),
          ));
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Scan Screen ---
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isFlashOn = false;
  double _zoomLevel = 0.5; // Example zoom state, range 0.0 to 1.0

  // TODO: Initialize and manage your camera controller here (e.g., MobileScannerController)

  @override
  void initState() {
    super.initState();
    // Initialize camera only after the first frame is built to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCameraAndScanner();
    });
  }

  Future<void> _initializeCameraAndScanner() async {
    // Request Camera Permission FIRST
    bool cameraGranted = await requestPermission(Permission.camera, context);
    if (!mounted) return; // Check if widget is still in the tree

    if (cameraGranted) {
      debugPrint("Camera permission granted, initializing camera/scanner...");
      // TODO: Initialize and start camera stream here (e.g., using mobile_scanner)
      // Example: _scannerController.start();
      // TODO: Set up listener for scanned codes:
      // _scannerController.barcodes.listen((barcodeCapture) {
      //    _handleScannedCode(barcodeCapture);
      // });
    } else {
      debugPrint("Camera permission denied, cannot start scanner.");
      // Optionally show a persistent message on the screen
    }
  }

  void _handleScannedCode(dynamic barcodeCapture) {
    // TODO: Implement logic when a code is scanned
    // - Stop scanning (optional, based on continuous scan mode)
    // - Play sound/vibrate (check settings)
    // - Add to history
    // - Show result dialog/screen with contextual actions
    debugPrint("Code Scanned! (Placeholder): $barcodeCapture");
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code Scanned! (Placeholder)')));
    // Example: _scannerController.stop(); // Stop after one scan
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    // TODO: Add logic to control actual camera flash using the controller
    // Example: _scannerController.toggleTorch();
    debugPrint("Flash Toggled: $_isFlashOn");
  }

  void _scanFromGallery() async {
    if (!mounted) return;
    bool photosGranted = await requestPermission(Permission.photos, context);
    if (!mounted || !photosGranted) return;

    debugPrint("Photo library permission granted, picking image...");
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        debugPrint("Image selected: ${image.path}");
        // TODO: Process the image file using a scanner library that supports files.
        // Example using mobile_scanner's analyzeImage:
        // bool found = await MobileScannerController().analyzeImage(image.path);
        // if (!found) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No code found in image.'))); }
        // If found, the listener set up in _initializeCameraAndScanner should trigger _handleScannedCode
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text('Image Scan (Not Implemented) - Path: ${image.path}')));
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error selecting image.')));
    }
  }

  void _handleZoom(double value) {
    setState(() {
      _zoomLevel = value;
    });
    // TODO: Control camera zoom using the controller
    // Example: _scannerController.setZoomScale(value);
    debugPrint("Zoom changed: $_zoomLevel");
  }

  @override
  void dispose() {
    // TODO: Dispose camera controller here
    // Example: _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final scanWindowSize = screenSize.width * 0.65;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // --- Camera Preview ---
          // TODO: Replace Container with actual Camera Preview Widget
          // Example: MobileScanner( controller: _scannerController, ... )
          Container(
            color: Colors.black,
            child: const Center(
                child: Text("Camera Preview Area",
                    style: TextStyle(color: Colors.grey))),
          ),

          // --- UI Overlay ---
          Column(
            children: [
              const Spacer(flex: 2), // Pushes content down
              Text(
                "Point camera at QR or barcode",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    shadows: const [Shadow(blurRadius: 2)]),
              ),
              const SizedBox(height: 20),
              // --- Scan Window ---
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    // The border/reticle
                    width: scanWindowSize, height: scanWindowSize,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.cyan.withOpacity(0.7), width: 2.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  // --- Animated Scan Line (Placeholder) ---
                  // TODO: Implement animation for this line
                  Container(
                    width: scanWindowSize * 0.9, height: 2.5,
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withAlpha(150),
                          blurRadius: 8.0,
                          spreadRadius: 2.0,
                        ),
                      ],
                    ),
                    margin: const EdgeInsets.only(
                        top: 0), // Adjust Y position if needed
                  ),
                ],
              ),
              const Spacer(flex: 3), // Pushes bottom bar space up
            ],
          ),

          // --- Top Control Buttons ---
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildOverlayButton(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    'Toggle Flash',
                    _toggleFlash),
                _buildOverlayButton(
                    Icons.image_search, 'Scan from Gallery', _scanFromGallery),
              ],
            ),
          ),

          // --- Zoom Slider ---
          Positioned(
            // Position vertically centered relative to scan window (approx)
            top: screenSize.height * 0.5 - 100, // Adjust centering as needed
            bottom: screenSize.height * 0.5 - 100,
            right: 5, width: 50,
            child: RotatedBox(
              quarterTurns: 1, // Vertical slider
              child: Slider(
                value: _zoomLevel,
                min: 0.0,
                max: 1.0,
                activeColor: Colors.cyan,
                inactiveColor: Colors.white30,
                onChanged: _handleZoom,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for semi-transparent overlay buttons
  Widget _buildOverlayButton(
      IconData icon, String tooltip, VoidCallback onPressed) {
    return Container(
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

// --- History Screen ---
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // TODO: Replace dummy data with actual data loaded from storage/state management
  final List<Map<String, dynamic>> _scannedItems = [
    {
      'type': 'Website',
      'data': 'https://flutter.dev',
      'icon': Icons.link,
      'color': Colors.blue,
      'timestamp': DateTime.now().subtract(const Duration(hours: 1))
    },
    {
      'type': 'Text',
      'data': 'Hello from Flutter QR Scanner!',
      'icon': Icons.text_fields,
      'color': Colors.orange,
      'timestamp': DateTime.now().subtract(const Duration(hours: 2))
    },
    {
      'type': 'Email',
      'data': 'mailto:support@example.com?subject=Help Request',
      'icon': Icons.email_outlined,
      'color': Colors.pinkAccent,
      'timestamp': DateTime.now().subtract(const Duration(days: 1))
    },
    {
      'type': 'Barcode: UPC-A',
      'data': '012345678905',
      'icon': Icons.barcode_reader,
      'color': Colors.redAccent,
      'timestamp': DateTime.now().subtract(const Duration(days: 1))
    },
    {
      'type': 'Contact',
      'data':
          'BEGIN:VCARD\nVERSION:3.0\nN:Doe;John;;;\nFN:John Doe\nORG:Example Corp.\nTEL;TYPE=WORK,VOICE:(123) 456-7890\nEMAIL:john.doe@example.com\nEND:VCARD',
      'icon': Icons.person_outline,
      'color': Colors.purpleAccent,
      'timestamp': DateTime.now().subtract(const Duration(days: 2))
    },
    {
      'type': 'Phone Number',
      'data': 'tel:+11234567890',
      'icon': Icons.phone_outlined,
      'color': Colors.deepPurpleAccent,
      'timestamp': DateTime.now().subtract(const Duration(days: 3))
    },
    {
      'type': 'Wi-Fi',
      'data': 'WIFI:S:MyHomeNetwork;T:WPA;P:SecretPassword123;;',
      'icon': Icons.wifi,
      'color': Colors.lightBlueAccent,
      'timestamp': DateTime.now().subtract(const Duration(days: 4))
    },
    {
      'type': 'Geo Location',
      'data': 'geo:40.7128,-74.0060?q=New+York+City',
      'icon': Icons.location_on_outlined,
      'color': Colors.red,
      'timestamp': DateTime.now().subtract(const Duration(days: 5))
    },
    {
      'type': 'Calendar Event',
      'data':
          'BEGIN:VEVENT\nSUMMARY:Project Deadline\nDTSTART:20241220T090000Z\nDTEND:20241220T100000Z\nLOCATION:Office\nDESCRIPTION:Final project submission due.\nEND:VEVENT',
      'icon': Icons.event,
      'color': Colors.teal,
      'timestamp': DateTime.now().subtract(const Duration(days: 6))
    },
  ];
  final List<Map<String, dynamic>> _createdItems = [
    {
      'type': 'Website',
      'data': 'https://pub.dev',
      'icon': Icons.link,
      'color': Colors.blue,
      'timestamp': DateTime.now().subtract(const Duration(minutes: 10))
    },
    {
      'type': 'Text',
      'data': 'Generated QR Code',
      'icon': Icons.text_fields,
      'color': Colors.orange,
      'timestamp': DateTime.now().subtract(const Duration(minutes: 30))
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            }),
        title: const Text('History'),
        actions: [
          // TODO: Add Filter/Sort/Search Icons here later
          IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search History (Not Implemented)',
              onPressed: () {/* TODO */}),
          IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear All History (Not Implemented)',
              onPressed: () {/* TODO: Show confirmation & clear */}),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Scanned'),
            Tab(text: 'Created'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoryList(_scannedItems),
          _buildHistoryList(_createdItems),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
          child: Text("No history yet.",
              style: Theme.of(context).textTheme.bodyMedium));
    }

    // TODO: Add Sorting/Filtering controls interaction here if icons are added to AppBar

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        String displayData = item['data'];
        // Attempt to show a more readable summary for complex types
        if (item['type'] == 'Contact' ||
            item['type'] == 'Wi-Fi' ||
            item['type'] == 'Calendar Event' ||
            item['type'] == 'Geo Location') {
          displayData = _summarizeComplexData(item['type'], item['data']);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            clipBehavior:
                Clip.antiAlias, // Ensures InkWell ripple stays within bounds
            child: InkWell(
              // Make the whole card tappable
              onTap: () {
                _showContextualActions(context, item);
              },
              child: Padding(
                // Add padding inside InkWell
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          (item['color'] as Color).withOpacity(0.15),
                      child: Icon(item['icon'], color: item['color'], size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['type'],
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(
                            displayData,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.8)),
                          ),
                          const SizedBox(height: 4),
                          // Optional: Display timestamp
                          Text(
                            _formatTimestamp(item['timestamp']),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Copy Button
                    IconButton(
                      icon: Icon(Icons.copy_outlined,
                          size: 20,
                          color: Theme.of(context)
                              .iconTheme
                              .color
                              ?.withOpacity(0.6)),
                      tooltip: 'Copy Raw Data',
                      padding: EdgeInsets.zero, // Reduce padding
                      constraints: const BoxConstraints(), // Reduce padding
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: item['data']));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Raw data copied to clipboard'),
                              duration: Duration(seconds: 1)),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper to show summarized data for complex types in the list
  String _summarizeComplexData(String type, String data) {
    try {
      // Add basic error handling for parsing attempts
      switch (type) {
        case 'Contact':
          return data
              .split('\n')
              .firstWhere((line) => line.startsWith('FN:'),
                  orElse: () => data.split('\n').firstWhere(
                      (line) => line.startsWith('N:'),
                      orElse: () => 'Contact Details'))
              .split(':')
              .last;
        case 'Wi-Fi':
          return data
              .split(';')
              .firstWhere((part) => part.startsWith('S:'),
                  orElse: () => 'Wi-Fi Network')
              .substring(2);
        case 'Calendar Event':
          return data
              .split('\n')
              .firstWhere((line) => line.startsWith('SUMMARY:'),
                  orElse: () => 'Calendar Event')
              .substring(8);
        case 'Geo Location':
          return data.split('?').first;
        default:
          return data;
      }
    } catch (_) {
      return 'Formatted Data Preview'; // Fallback if parsing fails
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    // TODO: Use intl package for better date formatting
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hr ago';
    return '${difference.inDays} days ago';
  }

  // --- Contextual Actions Logic ---
  void _showContextualActions(BuildContext context, Map<String, dynamic> item) {
    final type = item['type'] as String;
    final data = item['data'] as String;
    List<Widget> actions = [];

    void addAction(String title, IconData icon, VoidCallback onTap) {
      actions.add(ListTile(
        leading: Icon(icon, color: Theme.of(context).listTileTheme.iconColor),
        title: Text(title),
        onTap: () {
          Navigator.pop(context);
          onTap();
        }, // Close sheet & execute
      ));
    }

    // --- Determine Actions ---
    addAction('Share Raw Data', Icons.share_outlined,
        () => _shareData(data)); // Always offer share

    if (type.contains('Website') || data.startsWith('http')) {
      addAction('Open in Browser', Icons.open_in_browser,
          () => _launchURL(data, context));
      addAction('Copy Link', Icons.link, () => _copyToClipboard(data, 'Link'));
    } else if (type.contains('Email') || data.startsWith('mailto:')) {
      addAction(
          'Send Email', Icons.email_outlined, () => _launchURL(data, context));
      final emailAddress = data.replaceFirst('mailto:', '').split('?').first;
      if (emailAddress.isNotEmpty)
        addAction('Copy Email Address', Icons.copy,
            () => _copyToClipboard(emailAddress, 'Email address'));
      if (emailAddress.isNotEmpty)
        addAction('Add to Contacts', Icons.person_add_alt_1,
            () => _addEmailToContacts(emailAddress, context));
    } else if (type.contains('Phone') || data.startsWith('tel:')) {
      final phoneNumber = data.replaceFirst('tel:', '');
      addAction('Call Number', Icons.phone_outlined,
          () => _launchURL('tel:$phoneNumber', context));
      addAction('Send SMS', Icons.sms_outlined,
          () => _launchURL('sms:$phoneNumber', context));
      addAction('Copy Number', Icons.copy,
          () => _copyToClipboard(phoneNumber, 'Phone number'));
      addAction('Add to Contacts', Icons.person_add_alt_1,
          () => _addPhoneToContacts(phoneNumber, context));
    } else if (type.contains('SMS') ||
        data.startsWith('smsto:') ||
        data.startsWith('sms:')) {
      addAction(
          'Send SMS', Icons.sms_outlined, () => _launchURL(data, context));
      addAction('Copy SMS Data', Icons.copy,
          () => _copyToClipboard(data, 'SMS data'));
    } else if (type.contains('Contact')) {
      // vCard
      addAction('Add to Contacts', Icons.person_add_alt_1,
          () => _addVCardToContacts(data, context));
      // TODO: Add options to call/email/map by parsing vCard?
    } else if (type.contains('Wi-Fi')) {
      // WIFI: format
      addAction('Connect to Wi-Fi (Experimental)', Icons.wifi_tethering,
          () => _connectToWifi(data, context));
      addAction('Copy Network Name (SSID)', Icons.copy,
          () => _copyWifiDetail(data, 'S:', 'Network name'));
      addAction('Copy Password', Icons.password_outlined,
          () => _copyWifiDetail(data, 'P:', 'Password'));
    } else if (type.contains('Geo')) {
      // geo: format
      addAction(
          'Open in Maps', Icons.map_outlined, () => _launchURL(data, context));
      addAction('Copy Coordinates', Icons.copy,
          () => _copyToClipboard(data.split('?').first, 'Coordinates'));
    } else if (type.contains('Calendar Event')) {
      // iCalendar VEVENT
      addAction('Add to Calendar', Icons.event,
          () => _addEventToCalendar(data, context));
    } else if (type.contains('Barcode')) {
      // EAN, UPC etc.
      addAction(
          'Search Online',
          Icons.search,
          () => _launchURL(
              'https://www.google.com/search?q=${Uri.encodeComponent(data)}',
              context));
      addAction(
          'Copy Code', Icons.copy, () => _copyToClipboard(data, 'Barcode'));
    } else {
      // Default for Text, Clipboard
      addAction('Copy Text', Icons.copy, () => _copyToClipboard(data, 'Text'));
      addAction(
          'Search Web',
          Icons.search,
          () => _launchURL(
              'https://www.google.com/search?q=${Uri.encodeComponent(data)}',
              context));
    }

    // Add Copy Raw Data if it's different from primary copy action
    if (actions
            .where((w) =>
                w is ListTile && (w.title as Text).data!.contains('Copy '))
            .length <=
        1) {
      addAction('Copy Raw Data', Icons.copy_all_outlined,
          () => _copyToClipboard(data, 'Raw data'));
    }

    // --- Show the Actions ---
    showModalBottomSheet(
        context: context,
        builder: (ctx) => SafeArea(
            child: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min, children: actions))));
  }

  // --- Placeholder Action Handlers ---

  Future<void> _launchURL(String url, BuildContext context) async {
    debugPrint("Attempting to launch: $url");
    final uri = Uri.parse(url);
    // TODO: Get browser preference from settings (using SharedPreferences)
    // bool useInApp = (await SharedPreferences.getInstance()).getString(prefKeyBrowser) == 'in_app';
    bool useInApp = false; // Default to external for simplicity here

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri,
            mode: useInApp
                ? LaunchMode.inAppWebView
                : LaunchMode.externalApplication);
      } else {
        if (context.mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
      if (context.mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error opening: $url')));
    }
  }

  void _copyToClipboard(String text, String dataType) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$dataType copied to clipboard')));
    debugPrint("Copied: $text");
  }

  void _shareData(String data) {
    debugPrint("Sharing: $data");
    Share.share(data); // Use share_plus plugin
  }

  Future<void> _addEmailToContacts(String email, BuildContext context) async {
    if (!await requestPermission(Permission.contacts, context)) return;
    debugPrint("Adding email to contacts: $email");
    // TODO: Implement using contacts_service or flutter_contacts
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add Email to Contacts (Not Implemented)')));
  }

  Future<void> _addPhoneToContacts(String phone, BuildContext context) async {
    if (!await requestPermission(Permission.contacts, context)) return;
    debugPrint("Adding phone to contacts: $phone");
    // TODO: Implement using contacts_service or flutter_contacts
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add Phone to Contacts (Not Implemented)')));
  }

  Future<void> _addVCardToContacts(
      String vCardData, BuildContext context) async {
    if (!await requestPermission(Permission.contacts, context)) return;
    debugPrint("Adding vCard to contacts");
    // TODO: Implement vCard parsing and use contacts_service
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add vCard to Contacts (Not Implemented)')));
  }

  Future<void> _connectToWifi(String wifiData, BuildContext context) async {
    if (!await requestPermission(Permission.locationWhenInUse, context))
      return; // Needed for iOS Wifi info
    debugPrint("Attempting to connect to Wi-Fi");
    // TODO: Parse SSID, Password, Type from wifiData
    // TODO: Use wifi_connector or platform channels. Often restricted by OS.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Wi-Fi connection (Not Implemented - Requires OS integration)')));
  }

  void _copyWifiDetail(String wifiData, String prefix, String dataType) {
    // Very basic parsing
    try {
      final parts = wifiData.replaceFirst('WIFI:', '').split(';');
      String value = parts
          .firstWhere((p) => p.startsWith(prefix))
          .substring(prefix.length);
      _copyToClipboard(value, dataType);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$dataType not found in QR code')));
    }
  }

  Future<void> _addEventToCalendar(
      String iCalData, BuildContext context) async {
    // Use calendarWriteOnly or calendarFullAccess based on need
    if (!await requestPermission(Permission.calendarWriteOnly, context)) return;
    debugPrint("Adding event to calendar");
    // TODO: Implement iCalData (VEVENT) parsing
    // TODO: Use the add_2_calendar plugin
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Add Event to Calendar (Not Implemented)')));
  }
}

// --- Settings Screen ---
class SettingsScreen extends StatefulWidget {
  final Function(ThemeMode)
      onThemeChanged; // Callback to update theme in main app

  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _vibrateEnabled = true;
  String _browserPreference = 'external';
  String _historyPreference = 'keep';
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true; // To show loading indicator initially

  // TODO: Add AudioPlayer instance if needed for sound feedback
  // final _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _soundEnabled = prefs.getBool(prefKeySound) ?? true;
        _vibrateEnabled = prefs.getBool(prefKeyVibrate) ?? true;
        _browserPreference = prefs.getString(prefKeyBrowser) ?? 'external';
        _historyPreference = prefs.getString(prefKeyHistory) ?? 'keep';
        String themePref = prefs.getString(prefKeyTheme) ?? 'system';
        _themeMode = themePref == 'light'
            ? ThemeMode.light
            : (themePref == 'dark' ? ThemeMode.dark : ThemeMode.system);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading settings: $e");
      setState(() => _isLoading = false); // Stop loading even on error
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load settings.')));
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) await prefs.setBool(key, value);
      if (value is String) await prefs.setString(key, value);
      debugPrint("Setting Updated: $key = $value");

      // If theme changed, update app globally via callback
      if (key == prefKeyTheme) {
        final newThemeMode = value == 'light'
            ? ThemeMode.light
            : (value == 'dark' ? ThemeMode.dark : ThemeMode.system);
        widget.onThemeChanged(newThemeMode); // Call the callback
        setState(() => _themeMode = newThemeMode); // Update local state too
      }

      // Provide immediate feedback (optional)
      if (key == prefKeySound && value == true) _playSound();
      if (key == prefKeyVibrate && value == true) _vibrate();

      // Refresh local state for non-theme settings
      if (key != prefKeyTheme) {
        setState(() {
          if (key == prefKeySound) _soundEnabled = value;
          if (key == prefKeyVibrate) _vibrateEnabled = value;
          if (key == prefKeyBrowser) _browserPreference = value;
          if (key == prefKeyHistory) _historyPreference = value;
        });
      }
    } catch (e) {
      debugPrint("Error saving setting $key: $e");
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not save setting.')));
    }
  }

  void _playSound() {
    // TODO: Play a short sound using audioplayers plugin
    debugPrint("Playing scan sound (placeholder)");
  }

  void _vibrate() {
    // TODO: Use vibration plugin
    debugPrint("Vibrating (placeholder)");
    // Vibration.vibrate(duration: 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionHeader('Scan Feedback'),
                SwitchListTile(
                  title: const Text('Sound on Scan'),
                  secondary: const Icon(Icons.volume_up_outlined),
                  value: _soundEnabled,
                  onChanged: (value) => _updateSetting(prefKeySound, value),
                ),
                SwitchListTile(
                  title: const Text('Vibrate on Scan'),
                  secondary: const Icon(Icons.vibration),
                  value: _vibrateEnabled,
                  onChanged: (value) => _updateSetting(prefKeyVibrate, value),
                ),
                _buildSectionHeader('Opening Links'),
                ListTile(
                  leading: const Icon(Icons.open_in_browser_outlined),
                  title: const Text('Default Browser'),
                  trailing: _buildDropdown<String>(
                    value: _browserPreference,
                    items: const [
                      DropdownMenuItem(
                          value: 'external', child: Text('External App')),
                      DropdownMenuItem(
                          value: 'in_app', child: Text('In-App Browser')),
                    ],
                    onChanged: (value) => _updateSetting(prefKeyBrowser, value),
                  ),
                ),
                _buildSectionHeader('Appearance'),
                ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: const Text('Theme'),
                  trailing: _buildDropdown<String>(
                    value: _themeMode == ThemeMode.light
                        ? 'light'
                        : (_themeMode == ThemeMode.dark ? 'dark' : 'system'),
                    items: const [
                      DropdownMenuItem(
                          value: 'system', child: Text('System Default')),
                      DropdownMenuItem(value: 'light', child: Text('Light')),
                      DropdownMenuItem(value: 'dark', child: Text('Dark')),
                    ],
                    onChanged: (value) => _updateSetting(prefKeyTheme, value),
                  ),
                ),
                _buildSectionHeader('History'),
                ListTile(
                  leading: const Icon(Icons.history_toggle_off_outlined),
                  title: const Text('Auto-Delete History'),
                  trailing: _buildDropdown<String>(
                    value: _historyPreference,
                    items: const [
                      DropdownMenuItem(
                          value: 'keep', child: Text('Keep Forever')),
                      DropdownMenuItem(
                          value: 'delete_30d',
                          child: Text('After 30 days')), /* Add more? */
                    ],
                    onChanged: (value) => _updateSetting(prefKeyHistory, value),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.delete_forever_outlined,
                      color: Colors.redAccent[100]),
                  title: Text('Clear Scan History',
                      style: TextStyle(color: Colors.redAccent[100])),
                  onTap: () {
                    /* TODO: Show confirmation dialog & clear history */ debugPrint(
                        "Clear History Tapped (Not Implemented)");
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Clear history action (placeholder)')));
                  },
                ),
                _buildSectionHeader('Other'),
                const ListTile(
                  leading: Icon(Icons.widgets_outlined),
                  title: Text('iOS Widget'),
                  subtitle: Text('Requires native Xcode setup.'),
                  enabled: false,
                ),
                ListTile(
                    leading: const Icon(Icons.star_outline),
                    title: const Text('Rate App'),
                    onTap: () {/* TODO: Link to App Store/Play Store */}),
                ListTile(
                    leading: const Icon(Icons.policy_outlined),
                    title: const Text('Privacy Policy'),
                    onTap: () {/* TODO: Launch URL */}),
                ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About'),
                    onTap: () {/* TODO: Show About Dialog */}),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    /* ... same as before ... */ return Padding(
      padding: const EdgeInsets.only(
          left: 16.0, right: 16.0, top: 20.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Helper for consistent dropdowns
  Widget _buildDropdown<T>(
      {required T value,
      required List<DropdownMenuItem<T>> items,
      required ValueChanged<T?> onChanged}) {
    return DropdownButton<T>(
      value: value,
      underline: Container(), // Remove underline
      items: items,
      onChanged: onChanged,
    );
  }
}

// --- Helper Barcode Icon Extension ---
extension BarcodeIcon on IconData {
  static const IconData barcode_reader =
      Icons.qr_code_scanner; // Re-using scanner icon
}
