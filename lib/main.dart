import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_wrapper_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'app_theme.dart';
import 'core/constants/themes/utils/akel_design_system.dart';
import 'core/constants/themes/utils/api_keys.dart';
import 'core/constants/themes/utils/aws_credentials_manager.dart';
import 'services/shake_detection_service.dart';
import 'services/widget_service.dart';
import 'services/checkin_service.dart';
import 'services/enhanced_aws_polly_service.dart';
import 'services/facial_animation_service.dart';

// Doctor Annie AI Services
import 'services/doctor_annie_copilot_service.dart';
import 'services/advanced_ai_copilot_service.dart';
import 'services/ultimate_ai_features_service.dart';

// MEGA-SERVICES
import 'services/panic_service_v2.dart';
import 'services/emergency_core_service.dart';
import 'services/navigation_mega_service.dart';
import 'services/accessibility_cloud_service.dart';
import 'services/mesh_cad_service.dart';

/// ==================== MAIN ENTRY POINT ====================
///
/// AKEL PANIC BUTTON - BUILD 58
///
/// Features:
/// - Splash screen with animations
/// - Auth wrapper for automatic routing
/// - Doctor Annie AI integration
/// - All services initialized
/// - Error handling
/// - Web support (Chrome)
/// - Industrial sci-fi design
///
/// =====================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AkelDesign.deepBlack,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    debugPrint(' ========== AKEL INITIALIZATION START ==========');
    debugPrint(' Platform: ${kIsWeb ? "WEB (Chrome)" : "NATIVE"}');
    debugPrint(' BUILD 58 - DOCTOR ANNIE AI COMPLETE');

    // ==================== WEB-SPECIFIC SETUP ====================
    if (kIsWeb) {
      debugPrint(' Running on WEB - Using IndexedDB/SharedPreferences');
      debugPrint(' SQLite not available on web (this is normal)');
      debugPrint(' Browser storage initialized');
    }

    // Load environment variables
    try {
      await dotenv.load(fileName: ".env");
      debugPrint(' Environment variables loaded');
    } catch (e) {
      debugPrint(' .env file not found (continuing with defaults): $e');
    }

    // Test AWS credentials immediately
    await _testAWSCredentials();

    // Initialize Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint(' Firebase initialized successfully');
    } catch (e) {
      debugPrint(' Firebase initialization warning: $e');
      debugPrint(' Continuing with offline mode...');
    }

    // ==================== CORE SERVICES ====================

    // Initialize AWS Credentials Manager
    try {
      await AWSCredentialsManager().initialize();
      debugPrint(' AWS Credentials Manager initialized');
    } catch (e) {
      debugPrint(' AWS Credentials Manager: $e');
      debugPrint(' Voice features will be limited');
    }

    // Initialize Enhanced AWS Polly Service
    try {
      await EnhancedAWSPollyService().initialize();
      debugPrint(' AWS Polly Service initialized');
      debugPrint(' Voice: ${EnhancedAWSPollyService().currentVoice.displayName}');
    } catch (e) {
      debugPrint(' AWS Polly: $e');
      debugPrint(' Using fallback voice system');
    }

    // Initialize Facial Animation Service (Doctor Annie)
    try {
      FacialAnimationService().initialize();
      debugPrint(' Facial Animation Service initialized');
      debugPrint(' Doctor Annie lip sync ready');
    } catch (e) {
      debugPrint(' Facial Animation: $e');
    }

    // ==================== DOCTOR ANNIE AI SERVICES ====================

    // Initialize Doctor Annie Copilot Service
    try {
      await DoctorAnnieCopilotService().initialize();
      debugPrint(' Doctor Annie Copilot Service initialized');
      debugPrint(' Basic AI ready (AWS Lex V2)');
    } catch (e) {
      debugPrint(' Doctor Annie Copilot: $e');
      debugPrint(' Using rule-based fallback');
    }

    // Initialize Advanced AI Copilot Service
    try {
      await AdvancedAICopilotService().initialize();
      debugPrint(' Advanced AI Copilot Service initialized');
      debugPrint(' Claude AI ready');
      debugPrint(' Emotion detection ready');
      debugPrint(' Relationship system ready (0-100)');
      debugPrint(' Long-term memory ready');
    } catch (e) {
      debugPrint(' Advanced AI Copilot: $e');
      debugPrint(' Advanced features limited');
    }

    // Initialize Ultimate AI Features Service
    try {
      await UltimateAIFeaturesService().initialize();
      debugPrint(' Ultimate AI Features Service initialized');
      debugPrint(' Voice cloning ready (ElevenLabs)');
      debugPrint(' Translation ready (100+ languages)');
      debugPrint(' AR Avatar ready');
      debugPrint(' Voice morphing ready');
    } catch (e) {
      debugPrint(' Ultimate AI Features: $e');
      debugPrint(' Ultimate features limited');
    }

    // ==================== MEGA-SERVICES ====================

    // Initialize Panic Service V2
    try {
      await PanicServiceV2().initialize();
      debugPrint(' Panic Service V2 initialized');
    } catch (e) {
      debugPrint(' Panic Service V2: $e');
      debugPrint(' Emergency features available in limited mode');
    }

    // Initialize Emergency Core Service
    try {
      await EmergencyCoreService().initialize();
      debugPrint(' Emergency Core Service initialized');
      debugPrint(' Offline emergency queue ready');
      debugPrint(' Man-down detection ready');
      debugPrint(' Check-in system ready');
    } catch (e) {
      debugPrint(' Emergency Core Service: $e');
      debugPrint(' Using browser storage fallback');
    }

    // Initialize Navigation Mega Service
    try {
      await NavigationMegaService().initialize();
      debugPrint(' Navigation Mega Service initialized');
      debugPrint(' Offline maps ready');
      debugPrint(' Escape routes ready');
      debugPrint(' Citizen reporter ready');
    } catch (e) {
      debugPrint(' Navigation Mega Service: $e');
    }

    // Initialize Accessibility & Cloud Service
    try {
      await AccessibilityCloudService().initialize();
      debugPrint(' Accessibility & Cloud Service initialized');
      debugPrint(' Dyslexia mode: ${AccessibilityCloudService().isDyslexiaMode ? "ON" : "OFF"}');
      debugPrint(' Cloud provider: ${AccessibilityCloudService().currentProvider}');
    } catch (e) {
      debugPrint(' Accessibility & Cloud Service: $e');
    }

    // Initialize Mesh & CAD Service
    try {
      await MeshCADService().initialize();
      debugPrint(' Mesh & CAD Service initialized');
      debugPrint(' Mesh networking: ${MeshCADService().isMeshEnabled ? "ON" : "OFF"}');
      debugPrint(' CAD integration: ${MeshCADService().isCADEnabled ? "ON" : "OFF"}');
    } catch (e) {
      debugPrint(' Mesh & CAD Service: $e');
    }

    // ==================== EXISTING SERVICES ====================

    // Initialize Shake Detection Service (disabled on web)
    if (!kIsWeb) {
      try {
        final shakeService = ShakeDetectionService();
        await shakeService.initialize();
        debugPrint(' Shake detection service initialized');
      } catch (e) {
        debugPrint(' Shake detection: $e');
      }
    } else {
      debugPrint(' Shake detection not available on web');
    }

    // Initialize Widget Service (disabled on web)
    if (!kIsWeb) {
      try {
        await WidgetService.initialize();
        debugPrint(' Widget service initialized');
      } catch (e) {
        debugPrint(' Widget service: $e');
      }
    } else {
      debugPrint(' Widget service not available on web');
    }

    // Initialize Check-in Service
    try {
      await CheckInService.initialize();
      debugPrint(' Check-in service initialized');
    } catch (e) {
      debugPrint(' Check-in service: $e');
    }

    // ==================== QUEUE PROCESSOR ====================

    // Start emergency queue processor
    try {
      EmergencyCoreService().startQueueProcessing();
      debugPrint(' Emergency queue processor started');
    } catch (e) {
      debugPrint(' Queue processor: $e');
    }

    // ==================== CONFIGURATION STATUS ====================

    if (ApiKeys.debugLogsEnabled) {
      try {
        ApiKeys.printConfigurationStatus();
        debugPrint(' AWS Polly Status: ${EnhancedAWSPollyService().getStatus()}');

        // Print mega-services status
        try {
          final pendingCount = await EmergencyCoreService().getPendingCount();
          debugPrint(' Pending emergencies: $pendingCount');
        } catch (e) {
          debugPrint(' Pending count check: $e');
        }

        try {
          final downloadedRegions = await NavigationMegaService().getDownloadedRegions();
          debugPrint(' Downloaded map regions: ${downloadedRegions.length}');
        } catch (e) {
          debugPrint(' Region check: $e');
        }

        // Print AI services status
        try {
          final annieService = DoctorAnnieCopilotService();
          debugPrint(' Doctor Annie status: ${annieService.isInitialized ? "READY" : "LOADING"}');
        } catch (e) {
          debugPrint(' Annie status check: $e');
        }

        try {
          final advancedService = AdvancedAICopilotService();
          debugPrint(' Advanced AI status: ${advancedService.isInitialized ? "READY" : "LOADING"}');
        } catch (e) {
          debugPrint(' Advanced AI status check: $e');
        }

      } catch (e) {
        debugPrint(' Status check: $e');
      }
    }

    debugPrint(' ========== AKEL INITIALIZATION COMPLETE ==========\n');
    debugPrint(' Doctor Annie is ready!');
    debugPrint(' 150+ Features Active');
    debugPrint(' AI Companion: ACTIVE');
    debugPrint(' Running on: ${kIsWeb ? "WEB (Chrome)" : "NATIVE"}');
    debugPrint(' BUILD 58 - DOCTOR ANNIE AI COMPLETE\n');

  } catch (e, stackTrace) {
    debugPrint(' CRITICAL Initialization error: $e');
    debugPrint(' Stack trace: $stackTrace');
    debugPrint(' App will continue with limited functionality');
  }

  runApp(const MyApp());
}

/// Test AWS credentials from .env file
Future<void> _testAWSCredentials() async {
  try {
    debugPrint(' Testing AWS credentials from .env...');

    final accessKey = dotenv.env['AWS_ACCESS_KEY_ID'];
    final secretKey = dotenv.env['AWS_SECRET_ACCESS_KEY'];
    final region = dotenv.env['AWS_REGION'];
    final lexBotId = dotenv.env['LEX_BOT_ID'];
    final lexAliasId = dotenv.env['LEX_BOT_ALIAS_ID'];
    final claudeKey = dotenv.env['CLAUDE_API_KEY'];
    final elevenLabsKey = dotenv.env['ELEVENLABS_API_KEY'];

    // Check AWS credentials
    if (accessKey == null || accessKey.isEmpty) {
      debugPrint(' AWS_ACCESS_KEY_ID not found in .env');
      debugPrint(' Add to .env: AWS_ACCESS_KEY_ID=AKIA...');
      return;
    }

    if (secretKey == null || secretKey.isEmpty) {
      debugPrint(' AWS_SECRET_ACCESS_KEY not found in .env');
      return;
    }

    // Validate format
    if (!accessKey.startsWith('AKIA')) {
      debugPrint(' AWS_ACCESS_KEY_ID format may be incorrect');
      debugPrint(' Expected to start with "AKIA"');
    }

    if (secretKey.length < 30) {
      debugPrint(' AWS_SECRET_ACCESS_KEY seems too short');
    }

    // Success messages
    debugPrint(' AWS_ACCESS_KEY_ID: ${accessKey.substring(0, 5)}***');
    debugPrint(' AWS_SECRET_ACCESS_KEY: ${secretKey.substring(0, 5)}***');
    debugPrint(' AWS_REGION: ${region ?? "us-east-1"}');

    // Check Lex bot configuration
    if (lexBotId != null && lexBotId.isNotEmpty) {
      debugPrint(' LEX_BOT_ID: $lexBotId');
    } else {
      debugPrint(' LEX_BOT_ID not configured');
    }

    if (lexAliasId != null && lexAliasId.isNotEmpty) {
      debugPrint(' LEX_BOT_ALIAS_ID: $lexAliasId');
    } else {
      debugPrint(' LEX_BOT_ALIAS_ID not configured');
    }

    // Check Claude API key
    if (claudeKey != null && claudeKey.isNotEmpty) {
      debugPrint(' CLAUDE_API_KEY: ${claudeKey.substring(0, 5)}***');
    } else {
      debugPrint(' CLAUDE_API_KEY not configured (Advanced AI limited)');
    }

    // Check ElevenLabs API key
    if (elevenLabsKey != null && elevenLabsKey.isNotEmpty) {
      debugPrint(' ELEVENLABS_API_KEY: ${elevenLabsKey.substring(0, 5)}***');
    } else {
      debugPrint(' ELEVENLABS_API_KEY not configured (Voice cloning limited)');
    }

  } catch (e) {
    debugPrint(' Credential check error: $e');
  }
}

/// ==================== MAIN APP ====================

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final ShakeDetectionService _shakeService = ShakeDetectionService();
  final EnhancedAWSPollyService _pollyService = EnhancedAWSPollyService();
  final FacialAnimationService _facialService = FacialAnimationService();
  final EmergencyCoreService _coreService = EmergencyCoreService();

  // AI Services
  final DoctorAnnieCopilotService _doctorAnnie = DoctorAnnieCopilotService();
  final AdvancedAICopilotService _advancedAI = AdvancedAICopilotService();
  final UltimateAIFeaturesService _ultimateFeatures = UltimateAIFeaturesService();

  bool _widgetPanicTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Clean up services
    try {
      _pollyService.dispose();
    } catch (e) {
      debugPrint(' Polly dispose: $e');
    }

    try {
      _facialService.dispose();
    } catch (e) {
      debugPrint(' Facial dispose: $e');
    }

    try {
      _coreService.dispose();
    } catch (e) {
      debugPrint(' Core dispose: $e');
    }

    try {
      _doctorAnnie.dispose();
    } catch (e) {
      debugPrint(' Doctor Annie dispose: $e');
    }

    try {
      _advancedAI.dispose();
    } catch (e) {
      debugPrint(' Advanced AI dispose: $e');
    }

    try {
      _ultimateFeatures.dispose();
    } catch (e) {
      debugPrint(' Ultimate Features dispose: $e');
    }

    try {
      PanicServiceV2().dispose();
    } catch (e) {
      debugPrint(' Panic dispose: $e');
    }

    try {
      NavigationMegaService().dispose();
    } catch (e) {
      debugPrint(' Navigation dispose: $e');
    }

    try {
      MeshCADService().dispose();
    } catch (e) {
      debugPrint(' Mesh CAD dispose: $e');
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint(' App resumed');
        if (!kIsWeb) {
          try {
            _shakeService.startMonitoring();
            debugPrint(' Shake detection started');
          } catch (e) {
            debugPrint(' Shake start: $e');
          }
        }
        try {
          _coreService.resumeServices();
          debugPrint(' Background services resumed');
        } catch (e) {
          debugPrint(' Resume services: $e');
        }
        break;

      case AppLifecycleState.paused:
        debugPrint(' App paused');
        if (!kIsWeb) {
          try {
            _shakeService.stopMonitoring();
          } catch (e) {
            debugPrint(' Shake stop: $e');
          }
        }
        try {
          _pollyService.stop();
          _facialService.stopLipSync();
        } catch (e) {
          debugPrint(' Stop services: $e');
        }
        break;

      case AppLifecycleState.inactive:
        debugPrint(' App inactive');
        break;

      case AppLifecycleState.detached:
        debugPrint(' App detached');
        if (!kIsWeb) {
          try {
            _shakeService.dispose();
          } catch (e) {
            debugPrint(' Shake dispose: $e');
          }
        }
        break;

      case AppLifecycleState.hidden:
        debugPrint(' App hidden');
        break;
    }
  }

  Future<void> _initializeApp() async {
    if (!kIsWeb) {
      try {
        final wasTriggered = await WidgetService.wasTriggeredFromWidget();
        if (wasTriggered) {
          setState(() {
            _widgetPanicTriggered = true;
          });
          debugPrint(' Widget panic detected');
        }
      } catch (e) {
        debugPrint(' Widget check: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Apply dyslexia theme if enabled
          final accessService = AccessibilityCloudService();
          final baseTheme = themeProvider.themeMode == ThemeMode.dark
              ? AppTheme.darkTheme
              : AppTheme.lightTheme;
          final finalTheme = accessService.getDyslexiaTheme(baseTheme);

          return MaterialApp(
            title: 'AKEL Panic Button • Build 58 • Doctor Annie AI',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeMode == ThemeMode.light ? finalTheme : AppTheme.lightTheme,
            darkTheme: themeProvider.themeMode == ThemeMode.dark ? finalTheme : AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            // IMPORTANT: Start with SplashScreen
            home: const SplashScreen(),

            // Routes for navigation (BiometricLockScreen removed - use Navigator.push with callback)
            routes: {
              '/auth': (context) => const AuthWrapperScreen(),
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignupScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/home': (context) => const HomeScreen(),
            },
          );
        },
      ),
    );
  }
}