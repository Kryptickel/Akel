# Akel Panic Button

A cross-platform emergency safety application built with Flutter that provides immediate access to emergency services and real-time location sharing.

## Features

### 🚨 Emergency Panic Button
- **Prominent panic button** on the home screen for immediate emergency activation
- **Silent activation** via long press for discrete emergency alerts
- **Visual and haptic feedback** to confirm activation
- **Automatic location sharing** with emergency contacts

### 👤 User Profile Management
- **Registration form** for new users with profile information
- **Profile picture** support with image picker
- **Personal information** storage (Name, Age, Sex, Address)
- **Secure local storage** of user data

### 📍 Real-Time Location Sharing
- **GPS location tracking** with high accuracy
- **Live location sharing** with emergency contacts
- **Map integration** with Google Maps support
- **Location permission management** with user-friendly prompts

### ⚙️ Customizable Emergency Alerts
- **Custom emergency messages** with message templates
- **Emergency contact management** with phone number validation
- **Message preview** functionality
- **Bulk contact messaging** for emergency situations

### 📱 Offline Mode (SMS)
- **Direct SMS messaging** without internet connectivity
- **Emergency contact integration** for quick messaging
- **Custom number messaging** for ad-hoc emergency contacts
- **Location embedding** in SMS messages when available

### 🎨 User Experience
- **Intuitive navigation** with clear visual hierarchy
- **Accessibility features** with large touch targets
- **Emergency-focused color scheme** (red, orange, green indicators)
- **Responsive design** for various screen sizes
- **Dark/light theme support** following system preferences

## Installation

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio / Xcode for mobile development

### Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/Kryptickel/Akel.git
   cd Akel
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Permissions

The app requires the following permissions:

### Android
- `ACCESS_FINE_LOCATION` - For precise GPS location
- `ACCESS_COARSE_LOCATION` - For approximate location
- `SEND_SMS` - For offline emergency messaging
- `INTERNET` - For online features
- `READ_EXTERNAL_STORAGE` - For profile picture access
- `CAMERA` - For taking profile pictures

### iOS
- Location Services - For GPS tracking
- Photo Library - For profile pictures
- Camera - For taking photos

## App Architecture

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── user_profile.dart     # User data model
├── screens/
│   ├── splash_screen.dart    # Initial loading screen
│   ├── registration_screen.dart  # User registration
│   ├── home_screen.dart      # Main panic button interface
│   ├── location_screen.dart  # GPS location sharing
│   ├── settings_screen.dart  # Emergency settings
│   └── offline_mode_screen.dart  # SMS functionality
├── services/
│   ├── user_service.dart     # User data management
│   └── emergency_service.dart # Emergency functionality
├── widgets/
│   ├── panic_button.dart     # Main emergency button
│   ├── quick_action_card.dart # Navigation cards
│   └── custom_text_field.dart # Form inputs
└── utils/
    └── app_theme.dart        # Visual styling
```

## Key Features Implemented

### 1. Startup Profile for New Users ✅
- Complete registration form with validation
- Profile picture selection and storage
- Clear navigation flow
- Skip option for quick setup

### 2. Panic Button Activation ✅
- Large, prominent emergency button
- Visual pulse animation to draw attention
- Silent activation via long press
- Haptic feedback for user confirmation
- Emergency confirmation dialog

### 3. Real-Time Location Sharing ✅
- GPS location access with permission handling
- Live location display with coordinates
- Google Maps integration for location viewing
- Location sharing toggle with status indicators
- Location embedding in emergency messages

### 4. Customizable Alerts ✅
- Emergency message customization
- Message preview functionality
- Emergency contact management
- Default message templates
- Bulk contact messaging

### 5. Offline Mode ✅
- SMS messaging without internet
- Emergency contact integration
- Custom number messaging
- Location embedding in SMS
- Send confirmation dialogs

### 6. User-Friendly Navigation ✅
- Intuitive bottom navigation
- Quick action cards for easy access
- Clear visual hierarchy
- Accessible design with large buttons
- Help and guidance dialogs

### 7. Visual Appeal ✅
- Emergency-appropriate color scheme
- Clean, modern design
- Consistent iconography
- Smooth animations and transitions
- Dark/light theme support

## Usage

### First Time Setup
1. Launch the app
2. Complete the registration form with your details
3. Add emergency contacts in Settings
4. Customize your emergency message
5. Grant location permissions when prompted

### Emergency Activation
1. **Quick Alert**: Tap the red panic button
2. **Silent Alert**: Long press the panic button or use the floating action button
3. **Offline Mode**: Use the SMS feature when internet is unavailable

### Managing Settings
1. Access Settings from the home screen
2. Update emergency message and preview it
3. Add/remove emergency contacts
4. Configure location sharing preferences

## Future Enhancements

- Integration with local emergency services
- Wearable device support
- Voice command activation
- Geofencing for automatic alerts
- Community safety features
- AI-powered threat detection

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This app is designed to assist in emergency situations but should not be relied upon as the sole means of emergency communication. Always contact local emergency services directly when immediate help is needed.

## Support

For issues, questions, or contributions, please visit our GitHub repository or contact the development team.

---

**Emergency Contacts**: Always ensure your emergency contacts are up-to-date and test the functionality regularly to ensure it works when needed.